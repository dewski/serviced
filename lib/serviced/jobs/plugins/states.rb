module Serviced
  module Jobs
    module Plugins
      module States
        extend ActiveSupport::Concern

        def enable
          @service.enable
        end

        def disable
          @service.disable
        end
      end
    end
  end
end
