require 'test_helper'

describe Serviced::Base do
  it "should be enabled by default" do
    assert Google.serviced_enabled?
  end
end
