require 'serviced/jobs/base'

module Serviced
  module Jobs
    class CreateServices < Base
      # The default queue that all Serviced jobs will run under.
      #
      # Returns symbol of queue name.
      def self.queue
        :serviced
      end

      # Serviced::Jobs::CreateServices is responsible for iterating through each
      # of the subjects valid services and persist them into the database.
      #
      # subject_klass - The class name of the subject that hosts the serviced objects.
      # subject_id    - ID for the Subject to load.
      #
      # Returns nothing.
      def self.perform(subject_klass, subject_id)
        @args = [subject_klass, subject_id]

        if subject = subject_klass.constantize.find(subject_id)
          new(subject).perform
        end
      end

      def initialize(subject)
        @subject = subject
      end

      def process
        @subject.create_services
      end
    end
  end
end
