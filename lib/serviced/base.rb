require 'serviced/jobs/create_services'

module Serviced
  module Base
    extend ActiveSupport::Concern

    class MissingServiceError < StandardError; end

    module ClassMethods
      # Load all services to the class.
      #
      # services - string or symbol arguments of service names.
      #
      # Returns nothing.
      def serviced(*services)
        services.each do |name|
          if Serviced.service_exists?(name)
            self.services |= [name.to_sym]
          end
        end
      end
    end

    included do
      class << self
        attr_accessor :services
      end
      self.services = []

      validate :validate_services, :if => :serviced_enabled?
      after_update :refresh_services, :if => :serviced_enabled?
      before_destroy :destroy_services, :if => :serviced_enabled?
      after_commit :enqueue_service_creation, :on => :create, :if => :serviced_enabled?
    end

    def serviced_enabled?
      true
    end

    def enqueue_service_creation
      pk = send(self.class.primary_key)
      Serviced.enqueue(Serviced::Jobs::CreateServices, self.class.name, pk)
    end

    def create_services
      self.class.services.each do |name|
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
        service.enqueue_refresh
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
      if self.class.services.include?(name.to_sym)
        Serviced.services[name.to_sym].for(self)
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
        if service = service(service)
          service.validate(self)
        end
      end
    end
  end
end
