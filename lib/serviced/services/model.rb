module Serviced
  module Services
    class Model
      include MongoMapper::Document

      key :started_working_at, Time, :default => lambda { Time.now.utc }
      key :finished_working_at, Time
      key :candidate_id, Integer
      key :last_refreshed_at, Time

      timestamps!

      class << self
        attr_accessor :refresh_interval

        # Sets the service's refresh interval.
        #
        # time - Time interval for refresh rate.
        #
        # Returns Fixnum of timestamp if time is nil.
        def refresh_interval(time=nil)
          if time.nil?
            @refresh_interval
          else
            @refresh_interval = time
          end
        end

        # The abstract method that handles loading the associated
        # service document.
        #
        # Raises NotImplementedError until implemented in subclass.
        def for(object)
          raise NotImplementedError, "#{self.class} has not implemented Class.for(object)"
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

      refresh_interval 1.day

      # The abstract method that should prevent a service from triggering if the
      # condition is not met.
      #
      # Raises NotImplementedError until implemented in subclass.
      def active?
        raise NotImplementedError, "#{self.class} has not implemented #active?"
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
        self.started_working_at = Time.now.utc
        save!
      end

      def finished!
        self.finished_working_at = Time.now.utc
        save!
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

      # Determines if the current service needs to be refreshed by taking the
      # last_refreshed_at and comparing it to the service's refresh_interval
      # window.
      #
      # Returns true if expired, false if not.
      def expired?
        return false if !last_refreshed_at?
        last_refreshed_at <= (Time.now.utc - self.class.refresh_interval)
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
        self.last_refreshed_at = Time.now.utc
      end

      # Finds the associated Candidate based on the candidate_id.
      #
      # Returns Candidate if found.
      def candidate
        Candidate.find candidate_id
      end

      def forced_refresh?
        !!@forced_refresh
      end

      private

      def with_expiration
        return false if !active? || (!expired? && !forced_refresh?)
        yield
        refreshed
        save!
      end
    end
  end
end
