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
    end
  end
end
