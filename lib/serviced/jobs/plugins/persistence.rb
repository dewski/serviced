module Serviced
  module Jobs
    module Plugins
      module Persistence
        extend ActiveSupport::Concern

        def destroy_service
          @service.reset_identifier
          @service.destroy
        end
      end
    end
  end
end
