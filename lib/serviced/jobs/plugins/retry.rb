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
                "If you overrided Serviced::Jobs::Refresh be sure to set @args in #{self}.perform."
            end

            Serviced.enqueue(self, *Array(@args))
          end

          # Retries the job in the future with the original arguments given to
          # Class.perform.
          #
          # seconds - The amount of time in seconds to perform the job.
          #
          # Returns true if requeued, false if not.
          def delayed_requeue(seconds = 60)
            unless defined?(@args)
              raise RuntimeError, "Attempted to requeue #{self} but there were no args present." \
                "If you overrided Serviced::Jobs::Refresh be sure to set @args in #{self}.perform."
            end

            Resque.enqueue_in(seconds, self, *Array(@args))
          end
        end

        def requeue
          self.class.requeue
        end

        def delayed_requeue(seconds = 60)
          self.class.delayed_requeue(seconds)
        end
      end
    end
  end
end
