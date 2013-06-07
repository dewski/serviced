require 'test_helper'
require 'serviced/jobs/partition'

describe Serviced::Jobs::Partition do
  describe "evens" do
    before do
      @partition = Serviced::Jobs::Partition.new(24, 48)
    end

    it "should partition across total records" do
      assert_equal @partition.total, @partition.partition.inject(:+)
      assert_equal ([2] * 24), @partition.partition
    end
  end

  describe "odds" do
    before do
      @partition = Serviced::Jobs::Partition.new(2, 5)
    end

    it "should split from interval" do
      assert_equal 2, @partition.split
    end

    it "should have non remaining" do
      assert_equal 1, @partition.remaining
    end

    it "should partition evenly" do
      assert_equal @partition.total, @partition.partition.inject(:+)
      assert_equal [2, 3], @partition.partition
    end
  end

  describe "smaller total than interval" do
    before do
      @partition = Serviced::Jobs::Partition.new(2, 1)
    end

    it "should partition evenly" do
      assert_equal @partition.total, @partition.partition.inject(:+)
      assert_equal [1, 0], @partition.partition
    end
  end
end
