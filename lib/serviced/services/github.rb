require 'serviced/services/model'
require 'serviced/services/github/repository'

module Serviced
  module Services
    class GitHub < Model
      key :username
      key :profile_url
      key :avatar_url
      key :company
      key :biography
      key :repo_count, Integer, :default => 0
      key :following_count, Integer, :default => 0
      key :followers_count, Integer, :default => 0

      many :repositories, :class_name => 'Serviced::Services::Repository'

      refresh_interval 1.day

      after_create :populate_service

      def self.for(candidate)
        find_or_initialize_by_candidate_id_and_username \
          candidate.id,
          candidate.github_identifier
      end

      def active?
        username?
      end

      def validate(model)
        begin
          account
        rescue Octokit::NotFound
          model.errors.add(:base, "#{username} does not exist on GitHub. Provide a valid GitHub username.")
        end
      end

      def populate_service
        Serviced.enqueue(Serviced::GitHub::Start, candidate_id)
      end

      def refresh
        with_expiration do
          store_account_data
          store_account_repositories
        end
      end

      def store_account_data
        self.profile_url     = account.html_url
        self.avatar_url      = account.avatar_url
        self.company         = account.company
        self.biography       = account.biography
        self.repo_count      = account.public_repos
        self.following_count = account.following
        self.followers_count = account.followers
      end

      def store_account_repositories
        self.repositories.destroy_all

        public_repositories.each do |repository|
          self.repositories << Repository.from(repository)
        end
      end

      def account
        @account ||= connection.user username
      end

      def public_repositories
        connection.repositories username, :per_page => 200
      end

      private

      def connection
        @connection ||= Octokit::Client.new(:login => Hire.octokit_login, :oauth_token => Hire.octokit_oauth_token)
      end
    end
  end
end
