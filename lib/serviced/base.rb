require 'active_support/core_ext/class/attribute'
require 'active_support/concern'
require 'serviced/jobs/create_services'

module Serviced
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      # Load all services to the class.
      #
      # services - string or symbol of service names.
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
      class_attribute :services
      self.services = []

      before_destroy :destroy_services, :if => :serviced_enabled?
      after_commit :enqueue_service_creation, :on => :create, :if => :serviced_enabled?
      after_update :queue_dirty_service_refreshes, :if => :serviced_enabled?
      after_update :destroy_removed_services, :if => :serviced_enabled?
    end

    def serviced_enabled?
      true
    end

    # To avoid any services preventing the model from saving the services
    # are created in the background.
    #
    # Returns nothing.
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
        refresh_service(service)
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
        Serviced.fetch_service(name).for(self)
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

    private

    # After a subject has been updated we need to make sure that any services
    # that have had their identifier changed are refreshed.
    #
    # Returns nothing.
    def queue_dirty_service_refreshes
      changed_columns = previous_changes.keys.select do |column|
        column.match(/\A[a-z0-9_]+\_identifier\Z/)
      end

      updated_columns = changed_columns.collect do |column|
        before, after = previous_changes[column]
        after.present?
      end

      changed_services = updated_columns.collect do |column|
        column.sub('_identifier', '')
      end

      changed_services.each do |service|
        if self.class.services.include?(service.to_sym)
          refresh_service(service)
        end
      end
    end

    # After a subject has been updated we need to check if any services have
    # been cleared. Any services that have been cleared need to be removed.
    #
    # Returns nothing.
    def destroy_removed_services
      changed_columns = previous_changes.keys.select do |column|
        column.match(/\A[a-z0-9_]+\_identifier\Z/)
      end

      removed_columns = changed_columns.collect do |column|
        before, after = previous_changes[column]
        after.nil?
      end

      removed_services = removed_columns.collect do |column|
        column.sub('_identifier', '')
      end

      removed_services.each do |name|
        service = service(name)

        if service.persisted?
          service.destroy
        end
      end
    end
  end
end
