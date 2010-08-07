module Arel
  module Nodes
    class Select < Arel::Nodes::Node
      attr_reader :columns, :sources, :wheres, :groups, :orders, :limits

      def initialize columns, sources, wheres, groups, orders, limits, engine = Table.engine
        @columns = columns
        @sources = sources
        @wheres  = wheres
        @groups  = groups
        @orders  = orders
        @limits  = limits
        @engine  = engine
      end

      def to_sql
        viz = Arel::Visitors::Sql2.new @engine
        viz.accept self
      end
    end
  end
end
