require 'active_support/rescuable'
require 'serviced/jobs/plugins/instrumentation'
require 'serviced/jobs/plugins/persistence'
require 'serviced/jobs/plugins/retry'

module Serviced
  module Jobs
    class Base
      include ActiveSupport::Rescuable
      include Plugins::Instrumentation
      include Plugins::Persistence
      include Plugins::Retry

      def self.args
        @args
      end
    end
  end
end
