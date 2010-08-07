module Arel
  module Nodes
    class Subquery < Arel::Nodes::Node
      attr_reader :expression

      def initialize expression
        @expression = expression
      end
    end
  end
end
