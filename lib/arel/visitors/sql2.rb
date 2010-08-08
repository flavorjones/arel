module Arel
  module Visitors
    class Sql2
      DISPATCH = {}

      def initialize engine
        @engine      = engine
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
          "FROM   #{o.sources.map { |c| visit c }.join(' ')}",
          ("WHERE  #{o.wheres.map { |c| visit c }.join(' AND ')}" unless o.wheres.empty?),
          ("ORDER BY #{o.orders.map { |c| visit c }.join(', ')}" unless o.orders.empty?),
          ("LIMIT  #{o.limits.map { |c| visit c }.join}" unless o.limits.empty?),
          (visit o.offset if o.offset),
        ].compact.join ' '
      end

      def visit_Arel_InnerJoin o
        "#{visit o.relation1} #{o.join_sql} #{visit o.relation2} ON #{o.predicates.map { |x| visit x }.join ' AND ' }"
      end

      def visit_Arel_Nodes_Subquery o
        "(#{visit o.expression}) AS subquery"
      end

      def visit_Arel_Nodes_Count o
        "COUNT(#{visit o.expression}) AS count_id"
      end

      def visit_Arel_Skip o
        "OFFSET #{o.skipped}"
      end

      def visit_Arel_Attribute o
        table = o.relation
        "#{quote_table_name(table.table_alias || table.name)}.#{quote_column_name(o.name)}"
      end
      alias :visit_Arel_Sql_Attributes_String :visit_Arel_Attribute
      alias :visit_Arel_Sql_Attributes_Integer :visit_Arel_Attribute
      alias :visit_Arel_Sql_Attributes_Time :visit_Arel_Attribute
      alias :visit_Arel_Sql_Attribute :visit_Arel_Attribute

      def visit_Arel_StringJoin o
        o.relation2
      end

      def visit_Arel_Value o
        o.value
      end

      def visit_Arel_Ascending o; 'ASC' end

      def visit_Arel_Order o
        o.orderings.map { |x| "#{visit x} #{visit o.direction}" }.join ', '
      end

      def visit_Arel_Project o
        o.projections.map { |x| visit x }.join ', '
      end

      def visit_Arel_Table o
        [
          quote_table_name(o.name),
          (o.table_alias ? quote_table_name(o.table_alias) : ''),
        ].join ' '
      end

      def visit_Arel_Where o
        o.predicates.map { |x| visit x }.join ' AND '
      end

      def visit_Arel_Take o
        o.taken
      end

      def visit_Arel_Distinct o
        "DISTINCT #{visit o.attribute}" +
          (o.alias ? " AS #{quote_column_name(o.alias)}" : '')
      end

      def visit_Arel_Expression o
        "#{o.function_sql}(#{visit o.attribute}) AS " +
          (o.alias ?
            quote_column_name(o.alias) :
            "#{o.function_sql.to_s.downcase}_id")
      end
      alias :visit_Arel_Maximum :visit_Arel_Expression
      alias :visit_Arel_Minimum :visit_Arel_Expression
      alias :visit_Arel_Average :visit_Arel_Expression
      alias :visit_Arel_Count :visit_Arel_Expression

      def visit_Arel_Predicates_Equality o
        "#{visit o.operand1} #{o.predicate_sql} #{visit o.operand2}"
      end
      alias :visit_Arel_Predicates_Inequality :visit_Arel_Predicates_Equality

      def visit_Fixnum o
        o.to_s
      end
      def visit_String o; o end

      def visit object
        method = object.class.name.gsub '::', '_'
        send "visit_#{method}".to_sym, object
        #send DISPATCH[object.class], object
      end

      self.private_instance_methods(false).each do |method|
        method = method.to_s
        next unless method =~ /^visit_(.*)$/

        constant = $1.split('_').inject(Object) { |m,s| m.const_get s }
        DISPATCH[constant] = method.to_sym
      end

      def quote_table_name name
        @connection.quote_table_name name
      end

      def quote_column_name name
        @connection.quote_column_name name
      end

      def quote value, column = nil
        @connection.quote value, column
      end
    end
  end
end

