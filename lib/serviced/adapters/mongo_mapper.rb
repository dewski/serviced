require 'mongo_mapper'

module Serviced
  module Adapters
    module MongoMapper
      extend ActiveSupport::Concern

      included do
        include Serviced::Services::Model
        include ::MongoMapper::Document

        key :subject_type
        key :subject_id, Integer
        key :identifier

        key :started_working_at, Time, :default => lambda { Time.now }
        key :finished_working_at, Time
        key :last_refreshed_at, Time
        key :disabled_at, Time

        timestamps!

        validates :subject_type, :presence => true
        validates :subject_id,   :presence => true, :uniqueness => { :scope => :subject_type }
        validates :identifier,   :presence => true

        after_create :enqueue_refresh
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
          subject_id = subject.send(subject.class.primary_key)
          subject_type = subject.class.model_name.to_s

          record = find_or_initialize_by_subject_type_and_subject_id(subject_type, subject_id)

          if record.persisted? && record.identifier != identifier
            record.update_attributes(:identifier => identifier)
          else
            record.identifier = identifier
          end

          record
        end
      end
    end
  end
end
