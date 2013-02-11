require 'serviced/services/model'
require 'serviced/services/dribbble/shot'

module Serviced
  module Services
    class Dribbble < Model
      key :username
      key :profile_url
      key :avatar_url
      key :shots_count, Integer, :default => 0
      key :likes_received_count, Integer, :default => 0
      key :following_count, Integer, :default => 0
      key :followers_count, Integer, :default => 0

      many :shots, :class_name => 'Serviced::Services::Shot'

      refresh_interval 1.day

      after_create :populate_service

      def self.for(candidate)
        find_or_initialize_by_candidate_id_and_username \
          candidate.id,
          candidate.dribbble_identifier
      end

      def active?
        username?
      end

      def validate(model)
        if account.created_at.nil?
          model.errors.add(:base, "The username \"#{username}\" does not exist on Dribbble. Provide a valid username or leave blank.")
        end
      end

      def refresh
        with_expiration do
          store_account_data
          store_account_shots
          save
        end
      end

      def populate_service
        Serviced.enqueue(Serviced::Dribbble::Start, candidate_id)
      end

      def store_account_data
        self.profile_url          = account.url
        self.avatar_url           = account.avatar_url
        self.shots_count          = account.shots_count
        self.following_count      = account.following_count
        self.followers_count      = account.followers_count
        self.likes_received_count = account.likes_received_count
      end

      def store_account_shots
        self.shots.clear

        account.shots.each do |shot|
          self.shots << Shot.from(shot)
        end
      end

      def account
        @account ||= ::Dribbble::Player.find username
      end
    end
  end
end
