module Arel
  module Visitors
    class OrderClauses < Arel::Visitors::ToSql
      def visit_Arel_Nodes_SelectStatement o
        o.orders.map { |x| visit x }
      end
    end
  end
end
