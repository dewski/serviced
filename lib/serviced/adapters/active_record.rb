require 'active_record'
require 'serviced/jobs/partition'

module Serviced
  module Adapters
    module ActiveRecord
      extend ActiveSupport::Concern

      included do
        include Serviced::Services::Model

        belongs_to :serviceable, :polymorphic => true

        validates :serviceable_type, :presence => true
        validates :serviceable_id,   :presence => true, :uniqueness => { :scope => :serviceable_type }
        validates :identifier,       :presence => true

        scope :working, -> { where('started_working_at > finished_working_at') }
        scope :finished, -> { where('finished_working_at >= started_working_at') }
        scope :stale, -> { order('last_refreshed_at ASC') }

        scope :disabled, -> { where.not(:disabled_at => nil) }
        scope :enabled, -> { where(:disabled_at => nil) }

        after_commit :enqueue_refresh, :on => :create
      end

      module ClassMethods
        # The Class.for method handles finding or initializing new Serviced
        # service documents for the given subject. The service document will
        # be prefilled with values needed to save the document if one is not
        # found.
        #
        # subject - The subject that the service model is associated to.
        #
        # Returns Serviced::Services::Model document.
        def for(subject)
          identifier = subject.send(identifier_column)
          scope = where({
            :serviceable_id   => subject.send(subject.class.primary_key),
            :serviceable_type => subject.class.model_name.to_s
          })
          record = scope.first_or_initialize(:identifier => identifier)

          if record.persisted? && record.identifier != identifier
            record.update_attributes(:identifier => identifier)
          end

          record
        end

        # Fetches the partitioned documents at the current hour for bulk refresh.
        #
        # Returns Array of ActiveRecord::Base instances 
        def bulk_refresh
          partition = Serviced::Jobs::Partition.new(24, count)
          document_limit = partition.at(Time.now.hour)

          enabled.finished.stale.limit(document_limit).find_each do |service|
            service.enqueue_refresh
          end
        end
      end
    end
  end
end
