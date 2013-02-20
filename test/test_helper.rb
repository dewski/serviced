require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
Bundler.require(:default, :test)

$:.unshift File.dirname(File.expand_path('../lib', __FILE__))
require 'minitest/autorun'
require 'serviced'
require 'models'
