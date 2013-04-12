require 'active_support/rescuable'
require 'serviced/jobs/plugins/retry'
require 'serviced/jobs/plugins/persistence'

module Serviced
  module Jobs
    class Base
      include ActiveSupport::Rescuable
      include Plugins::Retry
      include Plugins::Persistence
    end
  end
end
