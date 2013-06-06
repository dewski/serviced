require 'serviced/jobs/refresh'

module Serviced
  module Services
    module Model
      extend ActiveSupport::Concern

      module ClassMethods
        # The class that is used to interface with the subject. It is expected
        # to be a +ActiveRecord+ model.
        #
        ## TODO: Not sure if we should _ensure_ it's an ActiveRecord model though.
        #
        # Returns subject class.
        def subject_class(klass = nil)
          if klass.nil?
            if @subject_class.is_a?(String)
              @subject_class.constantize
            elsif @subject_class.respond_to?(:call)
              @subject_class.call
            elsif @subject_class.nil?
              raise("Missing subject class!")
            else
              @subject_class
            end
          else
            @subject_class = klass
          end
        end

        def subject_class?
          subject_class.present?
        end

        # The service name set for the given class, mostly used to know the
        # identifier column on the subject.
        #
        # Returns service name.
        def service_name(name = nil)
          if name.nil?
            @service_name ||= model_name.human.gsub(/\s+/, '').downcase.to_sym
          else
            @service_name = name
          end
        end

        def service_name?
          service_name.present?
        end

        # The column that the subject is expected to return which contains the
        # unique identifier for the service.
        #
        # Returns service identifier column.
        def identifier_column(column = nil)
          if column.nil?
            @identifier_column ||= "#{service_name}_identifier".to_sym
          else
            @identifier_column = column.to_sym
          end
        end

        def identifier_column?
          identifier_column.present?
        end

        # Allows a subclass to set its Serviced job class, if it differs from
        # the generic one.
        #
        # Returns the service class.
        def service_class(klass = nil)
          if klass.nil?
            @service_class ||= Serviced::Jobs::Refresh
          else
            @service_class = klass
          end
        end

        def service_class?
          service_class.present?
        end
      end

      # Determines if the service should be interacted with by knowing if it's
      # active.
      #
      # Returns true if active, false if not.
      def active?
        identifier? && enabled?
      end

      # The abstract method that handles refreshing a service's data.
      #
      # Raises NotImplementedError until implemented in subclass.
      def refresh
        raise NotImplementedError, "#{self.class}#refresh has not implemented"
      end

      # The abstract method that handles validations for each service.
      #
      # Raises NotImplementedError until implemented in subclass.
      def validate(model)
        raise NotImplementedError, "#{self.class}#validate(model) has not been implemented"
      end

      def working!
        update_attribute(:started_working_at, Time.now.utc)
      end

      def finished!
        update_attribute(:finished_working_at, Time.now.utc)
      end

      # Consider the service to be working if the finished working
      # at isn't bigger than the started working at timestamp.
      #
      # Returns true if working, false if not.
      def working?
        return false unless started_working_at?
        return true if started_working_at? && !finished_working_at?

        started_working_at > finished_working_at
      end

      def finished?
        !working?
      end

      def refresh!
        refresh
        mark_refreshed
      end

      def enable
        update_attribute(:disabled_at, nil)
      end

      def enabled?
        disabled_at.nil?
      end

      def disable
        update_attribute(:disabled_at, Time.now)
      end

      def disabled?
        disabled_at.present?
      end

      # Sets the last_refreshed_at to the current time.
      #
      # Returns current Time.
      def mark_refreshed
        update_attribute(:last_refreshed_at, Time.now.utc)
      end

      # Finds the associated subject based on the subject class and subject_id.
      #
      # Returns Subject if found.
      def subject
        @subject ||= self.class.subject_class.find(subject_id)
      end

      def clear_identifier
        subject.update_column(self.class.identifier_column, nil)
      end

      def enqueue_refresh
        return false unless active?

        Serviced.enqueue \
          self.class.service_class,
          self.class.service_name,
          self.class.subject_class.name,
          subject_id
      end
    end
  end
end
