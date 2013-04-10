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

module Serviced
  class MissingServiceError < StandardError; end

  # Direct mapping of service names to their service object.
  mattr_accessor :services
  @@services = {}

  # Direct mapping of service names to their service object.
  mattr_accessor :queue_class
  @@queue_class = Resque

  mattr_accessor :aliases
  @@aliases = {}

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

  def self.service_exists?(name)
    !!retrieve_service(name)
  rescue MissingServiceError
    false
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

require 'serviced/base'
require 'serviced/services/model'
