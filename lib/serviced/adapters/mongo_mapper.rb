module Serviced
  module Adapters
    module MongoMapper
      extend ActiveSupport::Concern

      included do
        include Serviced::Services::Model
        include ::MongoMapper::Document

        key :subject_id, Integer
        key :identifier

        key :started_working_at, Time, :default => lambda { Time.now }
        key :finished_working_at, Time
        key :last_refreshed_at, Time

        timestamps!

        validates :subject_id, :presence => true, :uniqueness => { :scope => :_type }
        validates :identifier, :presence => true

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
          find_or_initialize_by_subject_id_and_identifier(subject.id, subject.send(identifier_column))
        end
      end
    end
  end
end
