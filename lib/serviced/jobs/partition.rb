module Serviced
  module Jobs
    class Partition
      attr_accessor :interval
      attr_reader :total

      def initialize(interval, total)
        @interval = interval
        @total = total
      end

      def split
        if total < interval
          total
        else
          total / interval
        end
      end

      def remaining
        total % interval
      end

      def partition
        @partition ||= if total < interval # Total doesn't fulfil 1 interval
          [total] + ([0] * (interval - 1))
        elsif remaining.zero? # Interval divides evenly into total
          [split] * interval
        else # Uneven
          items = ([split] * (interval - 1))
          items << (total - items.inject(:+))
        end
      end

      def [](index)
        partition[index]
      end

      def at(index)
        partition[index]
      end
    end
  end
end
