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
          ("WHERE  #{o.wheres.map { |c| visit c }.join(' AND ')}" unless o.wheres.empty?),
          ("LIMIT  #{o.limits.map { |c| visit c }.join}" unless o.limits.empty?),
        ].join ' '
      end

      def visit_Arel_Sql_Attributes_Integer o
        table = o.relation
        "#{quote_table_name(table.name)}.#{quote_column_name(o.name)}"
      end
      alias :visit_Arel_Sql_Attributes_String :visit_Arel_Sql_Attributes_Integer

      def visit_Arel_Value o
        o.value
      end

      def visit_Arel_Project o
        o.projections.map { |x| visit x }.join ', '
      end

      def visit_Arel_Table o
        quote_table_name(o.name)
      end

      def visit_Arel_Where o
        o.predicates.map { |x| visit x }.join ' AND '
      end

      def visit_Arel_Take o
        o.taken
      end

      def visit_Arel_Maximum o
        "#{o.function_sql}(#{visit o.attribute}) AS " +
          (o.alias ?
            quote_column_name(o.alias) :
            "#{o.function_sql.to_s.downcase}_id")
      end
      alias :visit_Arel_Minimum :visit_Arel_Maximum
      alias :visit_Arel_Average :visit_Arel_Maximum

      def visit_Arel_Predicates_Equality o
        "#{visit o.operand1} #{o.predicate_sql} #{visit o.operand2}"
      end

      def visit_Fixnum o
        o.to_s
      end

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

