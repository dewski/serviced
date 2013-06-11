require 'active_record'

module Serviced
  module Adapters
    module ActiveRecord
      extend ActiveSupport::Concern

      included do
        include Serviced::Services::Model

        validates :subject_type, :presence => true
        validates :subject_id,   :presence => true, :uniqueness => { :scope => :subject_type }
        validates :identifier,   :presence => true

        scope :working, -> { where('started_working_at > finished_working_at') }
        scope :finished, -> {
          where('finished_working_at > started_working_at OR started_working_at = finished_working_at')
        }
        scope :stale, -> { order('last_refreshed_at ASC') }

        scope :disabled, -> { where('disabled_at IS NOT NULL') }
        scope :enabled, -> { where('disabled_at IS NULL') }

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
            :subject_id => subject.send(subject.class.primary_key),
            :subject_type => subject.class.model_name.to_s
          })
          record = scope.first_or_initialize(:identifier => identifier)

          if record.persisted? && record.identifier != identifier
            record.update_attributes(:identifier => identifier)
          end

          record
        end
      end
    end
  end
end
