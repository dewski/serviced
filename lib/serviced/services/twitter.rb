require 'serviced/services/model'

module Serviced
  module Services
    class Twitter < Model
      include TwitterClient

      key :username
      key :profile_url
      key :avatar_url
      key :biography
      key :twitter_uid, Integer
      key :private, Boolean, :default => false
      key :tweet_count, Integer, :default => 0
      key :following_count, Integer, :default => 0
      key :followers_count, Integer, :default => 0
      key :following_hubbers, Array
      key :followers_hubbers, Array

      before_create :store_account_data
      after_create :populate_service
      before_destroy :destroy_friendships

      refresh_interval 1.hour

      def self.for(candidate)
        find_or_initialize_by_candidate_id_and_username \
          candidate.id,
          candidate.twitter_identifier
      end

      def active?
        username?
      end

      # Validate that the Twitter user exists.
      #
      # Bypass validation if the model is already in the database
      # and there has been no update to the twitter_identifier column.
      #
      # Returns true if the username is valid, false if not.
      def validate(model)
        return true if model.persisted? && !model.changed.include?('twitter_identifier')

        begin
          account
        rescue ::Twitter::Error::NotFound
          model.errors.add(:base, "The username \"#{username}\" does not exist on Twitter. Please provide a valid username.")
        rescue ::Twitter::Error::TooManyRequests,
               ::Twitter::Error::Unauthorized,
               ::Twitter::Error::BadGateway,
               ::Twitter::Error::InternalServerError
          # If we hit our rate limit, don't fail on updating/creating the candidate.
          true
        end
      end

      def populate_service
        Serviced.enqueue(Serviced::Twitter::Start, candidate_id)
      end

      # Gathers the candidate's twitter account data by querying for their
      # avatar, biography, tweet count, following count, and followers count.
      #
      #
      #
      def refresh
        with_expiration do
          store_account_data
          store_github_friendships
        end
      end

      def following_hubbers_with_avatars
        following_hubbers.collect { |hubber|
          username = username_for_id hubber
          [username, cached_avatar_url(username)]
        }
      end

      def followers_hubbers_with_avatars
        followers_hubbers.collect { |hubber|
          username = username_for_id hubber
          [username, cached_avatar_url(username)]
        }
      end

      def account
        @account ||= twitter_client.user username
      end

      def store_account_data
        self.profile_url      = "https://twitter.com/#{username}"
        self.twitter_uid      = account.id
        self.avatar_url       = account.profile_image_url_https
        self.biography        = account.description
        self.tweet_count      = account.statuses_count
        self.following_count  = account.friends_count
        self.followers_count  = account.followers_count
        self.private          = account.protected?
        self
      end

      def store_account_data!
        store_account_data && save!
      end

      def timeline
        @timeline ||= twitter_client.user_timeline username
      end

      def following?(githubber_id)
        friendship.following?(githubber_id)
      end

      def followed_by?(githubber_id)
        friendship.followed_by?(githubber_id)
      end

      def store_github_friendships
        return if private?

        store_follower_associations
        store_following_associations
      end

      def store_following_associations
        self.following_hubbers.clear

        TwitterFriendshipService.cached_githubber_ids.each do |githubber_id|
          self.following_hubbers << githubber_id if following?(githubber_id)
        end
      end

      def store_following_associations!
        store_following_associations && save!
      end

      def store_followers_associations
        self.followers_hubbers.clear

        TwitterFriendshipService.cached_githubber_ids.each do |githubber_id|
          self.followers_hubbers << githubber_id if followed_by?(githubber_id)
        end
      end

      def store_followers_associations!
        store_followers_associations && save!
      end

      def cached_avatar_url(username)
        TwitterAvatarService.url(username)
      end

      def username_for_id(id)
        TwitterAvatarService.username_for_id(id)
      end

      def friendship
        @friendship ||= TwitterFriendshipService.new(twitter_uid)
      end

      # Before a candidate is destroyed, make sure to clear
      # out any redis keys that exist belonging to the Twitter account.
      #
      # Returns true if friendships are destroyed, false if not.
      def destroy_friendships
        friendship.destroy
      end
    end
  end
end
