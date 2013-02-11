$:.push File.expand_path('../lib', __FILE__)
require 'serviced/version'

Gem::Specification.new do |s|
  s.name = 'serviced'
  s.version = Serviced::VERSION
  s.summary = 'An interface to dealing with the common pain points while dealing with 3rd parties APIs'
  s.description = 'An interface to dealing with the common pain points while dealing with 3rd parties APIs'
  s.authors     = ['Garrett Bjerkhoel']
  s.email       = ['me@garrettbjerkhoel.com']
  s.platform    = Gem::Platform::RUBY

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'swish',         '0.8.1'
  s.add_dependency 'twitter',       '4.1.2'
  s.add_dependency 'octokit',       '1.8.1'
  s.add_dependency 'linkedin',      '0.3.7'

  s.add_dependency 'mongo_mapper',  '0.11.1'
  s.add_dependency 'bson_ext',      '~> 1.0.0'
end
