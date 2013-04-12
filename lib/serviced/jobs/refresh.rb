require 'serviced/jobs/base'

module Serviced
  module Jobs
    class Refresh < Base
      rescue_from Timeout::Error, Errno::ETIMEDOUT, :with => :requeue

      # The default queue that all Serviced jobs will run under.
      #
      # Returns symbol of queue name.
      def self.queue
        :serviced_refresh
      end

      # The main interface of starting Serviced refresh jobs.
      #
      # service_name  - The name of the service expected to refresh.
      # subject_klass - The class name of the subject that hosts the serviced objects.
      # subject_id    - ID for the Subject to load.
      #
      # Returns nothing.
      def self.perform(service_name, subject_klass, subject_id)
        @args = [service_name, subject_klass, subject_id]

        subject = subject_klass.constantize.find(subject_id)
        service = subject.service(service_name) if subject

        if subject && service
          new(subject, service).perform
        end
      end

      def initialize(subject, service)
        @subject = subject
        @service = service
      end

      # Where the bulk of the service updating should happen. If extending the
      # class this method should be overrided.
      #
      # Returns nothing.
      def process
        with_timestamps do
          @service.refresh!
        end
      end

      # Wraps the bulk of the job work by marking when the service has started
      # working and when it finishes so the appropriate data can be rendered.
      #
      # Returns nothing.
      def with_timestamps
        @service.working!
        yield
        @service.finished!
      end

      # This is where all job processing is expected to happen so the global
      # rescue handler can catch any and all exceptions to let ActiveSupport::Rescuable
      # fan them out.
      #
      # Returns nothing.
      def perform
        process
      rescue => exception
        rescue_with_handler(exception) || raise(exception)
      end
    end
  end
end
