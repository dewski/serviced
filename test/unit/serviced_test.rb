require 'test_helper'

describe Serviced do
  describe "service_exists?" do
    it "should know when services exist" do
      assert Serviced.service_exists?('twitter'), 'should work as string'
      assert Serviced.service_exists?(:twitter), 'should work as symbol'
    end

    it "should know when services dont exist" do
      refute Serviced.service_exists?('nyancat')
    end
  end

  describe "service_class" do
    it "should return service class when exists" do
      assert_equal Serviced::Services::Twitter, Serviced.service_class(:twitter)
    end

    it "should raise MissingServiceError for non-service" do
      assert_raises(Serviced::MissingServiceError) {
        Serviced.service_class('NyanCat')
      }
    end
  end
end
