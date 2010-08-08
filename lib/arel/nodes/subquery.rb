module Arel
  module Nodes
    class Subquery < Arel::Nodes::Node
      attr_reader :expression, :alias

      def initialize expression, aliaz = 'subquery'
        @expression = expression
        @alias      = aliaz
      end
    end
  end
end
