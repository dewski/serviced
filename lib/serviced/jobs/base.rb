require 'active_support/rescuable'
require 'serviced/jobs/plugins/retry'

module Serviced
  module Jobs
    class Base
      include ActiveSupport::Rescuable
      include Plugins::Retry
    end
  end
end
