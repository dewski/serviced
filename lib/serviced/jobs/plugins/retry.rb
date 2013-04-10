module Serviced
  module Jobs
    module Plugins
      module Retry
        extend ActiveSupport::Concern

        module ClassMethods
          # Retries the job with the original arguments given to Class.perform.
          #
          # Returns true if requeued, false if not.
          def requeue
            unless defined?(@args)
              raise RuntimeError, "Attempted to requeue #{self} but there were no args present." \
                "If you overrided Serviced::Jobs::Service be sure to set @args in #{self}.perform."
            end

            Serviced.enqueue(self, *Array(@args))
          end
        end

        def requeue
          self.class.requeue
        end
      end
    end
  end
end
