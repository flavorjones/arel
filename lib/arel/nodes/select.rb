module Arel
  module Nodes
    class Select < Arel::Nodes::Node
      attr_reader :columns, :sources, :wheres, :groups, :orders, :limits
      attr_reader :offset, :engine, :having

      def initialize columns, sources, wheres, groups, having, orders, limits, offset, engine = Table.engine
        @columns = columns
        @sources = sources
        @wheres  = wheres
        @groups  = groups
        @orders  = orders
        @having  = having
        @limits  = limits
        @offset  = offset
        @engine  = engine
      end

      def to_sql
        viz = Arel::Visitors::Sql2.new @engine
        viz.accept self
      end
    end
  end
end
