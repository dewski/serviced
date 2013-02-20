require 'resque'
require 'mongo_mapper'

MongoMapper.config = {
  'development' => {
    'host'      => '127.0.0.1',
    'port'      => ENV['GH_MONGODB_PORT'],
    'database'  => 'serviced'
  }
}
MongoMapper.connect('development')

require 'serviced/base'

module Serviced
  # Direct mapping of service names to their service object.
  mattr_accessor :services
  @@services = {}

  # Direct mapping of service names to their service object.
  mattr_accessor :queued_refreshes
  @@queued_refreshes = false

  # Direct mapping of service names to their service object.
  mattr_accessor :queue_class
  @@queue_class = Resque

  mattr_accessor :aliases
  @@aliases = {
    :github   => :git_hub,
    :linkedin => :linked_in
  }

  def self.queued_refreshes?
    !!@@queued_refreshes
  end

  def self.setup
    yield self
  end

  def self.enqueue(*args)
    @@queue_class.enqueue(*args)
  end

  def self.service_class(name)
    class_name = "Serviced::Services::#{aliases.fetch(name.to_sym, name).to_s.classify}"
    class_name.constantize
  rescue NameError
    raise MissingServiceError, "Missing service class for #{name.inspect} (#{class_name})."
  end

  def self.service_start_class(name)
    class_name = "Serviced::#{aliases.fetch(name.to_sym, name).to_s.classify}::Start"
    class_name.constantize
  rescue NameError
    raise "Missing service start class for #{name.inspect} (#{class_name})."
  end

  def self.service_exists?(name)
    !!retrieve_service(name)
  end

  def self.retrieve_service(name)
    if service = @@services[name.to_sym]
      service
    elsif service_class = service_class(name)
      @@services[name.to_sym] = service_class
    else
      raise MissingServiceError, "Missing #{name} service."
    end
  end
end
