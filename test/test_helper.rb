require 'rubygems'
require 'bundler/setup'

$:.unshift File.dirname(File.expand_path('../lib', __FILE__))
require 'minitest/autorun'
require 'serviced'
require 'models'
