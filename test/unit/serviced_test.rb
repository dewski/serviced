require 'test_helper'

describe Serviced do
  describe "setup" do
    it "should change existing values" do
      refute Serviced.queued_refreshes?
      Serviced.setup { |c| c.queued_refreshes = true }
      assert Serviced.queued_refreshes?
    end
  end

  describe "service_class" do
    it "should return service class when exists" do
      assert_equal Serviced::Services::Twitter, Serviced.service_class('Twitter')
    end

    it "should raise MissingServiceError for non-service" do
      assert_raises(Serviced::MissingServiceError) {
        Serviced.service_class('NyanCat')
      }
    end
  end
end
