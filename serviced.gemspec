$:.push File.expand_path('../lib', __FILE__)
require 'serviced/version'

Gem::Specification.new do |s|
  s.name = 'serviced'
  s.version = Serviced::VERSION
  s.summary = ''
  s.description = ''
  s.authors     = ['Garrett Bjerkhoel']
  s.email       = ['me@garrettbjerkhoel.com']
  s.platform    = Gem::Platform::RUBY

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'activesupport', '>= 2.0.0'
  s.add_dependency 'json'
  s.add_development_dependency 'tzinfo'
end
