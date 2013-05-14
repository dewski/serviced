module Serviced
  module Adapters
    module ActiveRecord
      extend ActiveSupport::Concern

      included do
        include Serviced::Services::Model

        attr_accessible :identifier

        validates :subject_type, :presence => true
        validates :subject_id, :presence => true, :uniqueness => { :scope => :subject_type }
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
          scope = where \
            :subject_id => subject.id,
            :subject_type => subject.class.model_name
          scope.first_or_initialize(:identifier => subject.send(identifier_column))
        end
      end
    end
  end
end
