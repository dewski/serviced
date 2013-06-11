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
    end
  end
end
