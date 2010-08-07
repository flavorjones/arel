module Arel
  module Nodes
    class Select < Arel::Nodes::Node
      attr_reader :columns, :sources, :wheres, :groups, :orders, :limits

      def initialize columns, sources, wheres, groups, orders, limits
        @columns = columns
        @sources = sources
        @wheres  = wheres
        @groups  = groups
        @orders  = orders
        @limits  = limits
      end
    end
  end
end
