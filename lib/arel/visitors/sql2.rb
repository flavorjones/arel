module Arel
  module Visitors
    class Sql2
      DISPATCH = {}

      def initialize environment
        @environment = environment
        @engine      = environment.engine
        @christener  = nil
        @connection  = nil
      end

      def accept object
        @engine.driver.connection_pool.with_connection do |connection|
          @connection = connection

          visit object
        end
      end

      private
      def visit_Arel_Nodes_Select o
        [
          "SELECT #{o.columns.map { |c| visit c }.join(', ')}",
          "FROM   #{o.sources.map { |c| visit c }.join(', ')}",
          "WHERE  #{o.wheres.map { |c| visit c }.join(' AND ')}",
          "LIMIT  #{o.limits.map { |c| visit c }.join}",
        ].join ' '
      end

      def visit_Arel_Project o
        o.projections.map { |x| x.value }.join ', '
      end

      def visit_Arel_Table o
        o.name
      end

      def visit_Arel_Where o
        o.predicates.map { |x| x.value }.join ' AND '
      end

      def visit_Arel_Take o
        o.taken
      end

      def visit object
        send DISPATCH[object.class], object
      end

      self.private_instance_methods(false).each do |method|
        method = method.to_s
        next unless method =~ /^visit_(.*)$/

        constant = $1.split('_').inject(Object) { |m,s| m.const_get s }
        DISPATCH[constant] = method.to_sym
      end
    end
  end
end

