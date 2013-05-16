require 'active_support/rescuable'
require 'serviced/jobs/plugins/instrumentation'
require 'serviced/jobs/plugins/persistence'
require 'serviced/jobs/plugins/retry'
require 'serviced/jobs/plugins/states'

module Serviced
  module Jobs
    class Base
      include ActiveSupport::Rescuable
      include Plugins::Instrumentation
      include Plugins::Persistence
      include Plugins::Retry
      include Plugins::States

      def self.args
        @args
      end

      attr_reader :subject
      attr_reader :service
    end
  end
end
