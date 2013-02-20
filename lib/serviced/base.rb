Dir[File.join(File.dirname(__FILE__), 'services', '*.rb')].each do |service|
  require service
end

module Serviced
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      # Load all services to the class.
      #
      # services - string or symbol arguments of service names.
      #
      # Returns nothing.
      def serviced(*services)
        self.services.clear

        services.each do |name|
          self.services += [name] if Serviced.service_exists?(name)
        end
      end
    end
    
    included do
      class_attribute :services
      self.services = []

      validate :validate_services, :if => :serviced_enabled?
      after_create :enqueue_service_creation, :if => :serviced_enabled?
      after_update :refresh_services, :if => :serviced_enabled?
      before_destroy :destroy_services, :if => :serviced_enabled?
    end

    def serviced_enabled?
      true
    end

    def enqueue_service_creation
      pk = send(self.class.primary_key)
      Serviced.enqueue(Serviced::CreateServices, pk)
    end

    def create_services
      self.class.services.each do |name|
        next unless send("#{name}_identifier?")

        if service = service(name)
          service.save
        end
      end
    end

    # Handle refreshing all subscribed services for the class.
    # If queued refreshes are enabled, background jobs will be triggered.
    #
    # Returns nothing.
    def refresh_services
      self.class.services.each do |service|
        next unless send("#{service}_identifier?")

        refresh_service service
      end
    end

    # Refreshes the requested service's data.
    #
    # name - Service name
    #
    # Returns boolean if service has been refreshed, raises MissingServiceError
    # if missing.
    def refresh_service(name)
      if service = service(name)
        class_name = Serviced.service_start_class(name)
        pk = send(self.class.primary_key)

        Serviced.enqueue(class_name, pk)
      else
        raise MissingServiceError, "Missing #{name} service."
      end
    end

    # Grabs the requested service and finds the associated document
    # based on the unique identifier for said service.
    #
    # name - Service name
    #
    # Returns Service instance if it exists, nil if missing.
    def service(name)
      if self.class.services.include?(name)
        Serviced.services[name].for(self)
      end
    end

    # Loops through all attached services and destroys them if they
    # exist when the parent model is destroyed.
    #
    # Returns nothing.
    def destroy_services
      self.class.services.each do |service|
        if service = service(service)
          service.destroy
        end
      end
    end

    def validate_services
      self.class.services.each do |service|
        next if !send("#{service}_identifier?")

        if service = service(service)
          service.validate(self)
        end
      end
    end
  end
end
