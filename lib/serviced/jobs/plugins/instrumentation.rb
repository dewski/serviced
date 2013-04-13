module Serviced
  module Jobs
    module Plugins
      module Instrumentation
        extend ActiveSupport::Concern

        module ClassMethods
          # The notification name to trigger all notifications under.
          #
          # Returns String.
          def notification_name(new_name = nil)
            if new_name.nil?
              @notification_name ||= name.split('::').reverse.join('.').downcase
            else
              @notification_name = new_name
            end
          end

          def notification_name?
            notification_name.present?
          end
        end

        protected

        # Helper method to instrument the type of service that is being processed
        # and the subject that the service belongs to.
        #
        # Returns nothing.
        def instrument
          ActiveSupport::Notifications.instrument(self.class.notification_name, instrumentation_options) do
            yield
          end
        end

        def publish_instrumentation
          ActiveSupport::Notifications.publish \
            self.class.notification_name,
            service.started_working_at,
            service.finished_working_at,
            service.id.to_s,
            instrumentation_options
        end

        def instrumentation_options
          {
            :args => self.class.args,
            :service_name => service.class.service_name,
            :subject => subject
          }
        end
      end
    end
  end
end
