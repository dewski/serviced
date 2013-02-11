require 'serviced/services/model'

module Serviced
  module Services
    class LinkedIn < Model
      key :username
      key :job_title

      refresh_interval 1.day

      def self.for(candidate)
        find_or_initialize_by_candidate_id_and_username \
          candidate.id,
          candidate.linkedin_identifier
      end

      def active?
        username?
      end

      def refresh
        with_expiration do
          update_attributes \
            :job_title => account.html_url
        end
      end

      def account
        @account ||= Octokit.user username
      end

      private

      def client
        @client ||= begin
          client = ::LinkedIn::Client.new(Hire.linkedin_api_key, Hire.linkedin_secret_key)
          tokens = Hire.linkedin_access_token.split(',')
          client.authorize_from_access(*tokens)
          client
        end
      end
    end
  end
end
