require 'test_helper'

describe Serviced::Base do
  before do
    @gmail = Gmail.new
  end

  it "should be enabled by default" do
    assert @gmail.serviced_enabled?
  end

  describe "setting enabled services" do
    it "should maintain seperate sets of services per class" do
      assert_equal [], Gmail.services
      assert_equal [], Hotmail.services
      Gmail.serviced(:twitter)
      assert_equal [:twitter], Gmail.services
      assert_equal [], Hotmail.services
    end
  end
end
