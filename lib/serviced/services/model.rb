require 'serviced/jobs/refresh'

module Serviced
  module Services
    class Model
      include MongoMapper::Document

      key :subject_id, Integer
      key :identifier
      key :started_working_at, Time, :default => lambda { Time.now.utc }
      key :finished_working_at, Time
      key :last_refreshed_at, Time

      timestamps!

      validates :subject_id, :presence => true, :uniqueness => { :scope => :_type }
      validates :identifier, :presence => true

      after_create :enqueue_refresh

      class << self
        # The class that is used to interface with the subject. It is expected
        # to be a +ActiveRecord+ model.
        #
        ## TODO: Not sure if we should _ensure_ it's an ActiveRecord model though.
        #
        # Returns subject class.
        def subject_class(klass = nil)
          if klass.nil?
            @subject_class || raise("Missing subject class!")
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

        # The Class.for method handles finding or initializing new Serviced
        # service documents for the given subject. The service document will
        # be prefilled with values needed to save the document if one is not
        # found.
        #
        # subject - The subject that the service model is associated to.
        #
        # Returns Serviced::Services::Model document.
        def for(subject)
          find_or_initialize_by_subject_id_and_identifier(subject.id, subject.send(identifier_column))
        end

        # Keep track of how long it takes for jobs to finish.
        #
        # Returns Hash of times.
        def worker_times
          initial = { :count => 0, :total_time => 0 }
          condition = { '_type' => self.to_s }
          reduce = %Q(function(doc, out) {
            var exists = doc.started_working_at && doc.finished_working_at;
            var finished = doc.finished_working_at > doc.started_working_at;
            if(exists && finished) {
              out.count++;
              out.total_time += doc.finished_working_at - doc.started_working_at;
            }
          })
          finalize = %Q(function(prev) {
            prev.total_time = prev.total_time / 1000;
            prev.mean_time = (prev.total_time / prev.count);
          })

          result = collection.group(:initial => initial, :cond => condition, :reduce => reduce, :finalize => finalize).first
          HashWithIndifferentAccess.new(result)
        end
      end

      # Determines if the service should be interacted with by knowing if it's
      # active.
      #
      # Returns true if active, false if not.
      def active?
        identifier?
      end

      # The abstract method that handles refreshing a service's data.
      #
      # Raises NotImplementedError until implemented in subclass.
      def refresh
        raise NotImplementedError, "#{self.class} has not implemented #refresh"
      end

      # The abstract method that handles validations for each service.
      #
      # Raises NotImplementedError until implemented in subclass.
      def validate(model)
        raise NotImplementedError, "#{self.class} has not implemented #validate"
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
        return true if finished_working_at.nil?

        started_working_at > finished_working_at
      end

      def finished?
        !working?
      end

      def refresh!
        @forced_refresh = true
        refresh
      ensure
        @forced_refresh = false
      end

      # Sets the last_refreshed_at to the current time.
      #
      # Returns current Time.
      def refreshed
        update_attribute(:last_refreshed_at, Time.now.utc)
      end

      def forced_refresh?
        !!@forced_refresh
      end

      # Finds the associated subject based on the subject class and subject_id.
      #
      # Returns Subject if found.
      def subject
        @subject ||= self.class.subject_class.find(subject_id)
      end

      def reset_identifier
        subject.update_column(self.class.identifier_column, nil)
      end

      def enqueue_refresh
        Serviced.enqueue \
          self.class.service_class,
          self.class.service_name,
          self.class.subject_class.name,
          subject_id
      end
    end
  end
end
