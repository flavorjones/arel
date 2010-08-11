module Arel
  module Nodes
    class Select < Arel::Nodes::Node
      attr_accessor :columns, :sources, :wheres, :groups, :orders, :limits
      attr_accessor :offset, :engine, :having, :joins

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
        @joins   = []
      end

      def to_sql
        viz = Arel::Visitors::Sql2.new @engine
        viz.accept self
      end
    end
  end
end
