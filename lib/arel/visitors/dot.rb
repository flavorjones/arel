module Arel
  module Visitors
    class Dot
      def initialize
        @nodes = []
        @edges = []
        @stack = []
        @callstack = []
        @seen  = {}
      end

      def accept object
        visit object
        to_dot
      end

      Node = Struct.new :name, :id
      Edge = Struct.new :name, :left, :right

      private
      def visit_Arel_Having o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :predicates) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Group o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :groupings) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Skip o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :skipped) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Order o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :orderings) { |t| visit t }
        call(o, :direction) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Nodes_Count o
        @stack.push o
        call(o, :expression) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Nodes_Subquery o
        @stack.push o
        call(o, :expression) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Nodes_Select o
        @stack.push o
        call(o, :columns) { |t| visit t }
        call(o, :sources) { |t| visit t }
        call(o, :wheres) { |t| visit t }
        call(o, :limits) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Maximum o
        visit_Arel_Attribute o
        @stack.push o
        call(o, :attribute) { |t| visit t }
        @stack.pop
      end
      alias :visit_Arel_Minimum :visit_Arel_Maximum
      alias :visit_Arel_Average :visit_Arel_Maximum
      alias :visit_Arel_Count :visit_Arel_Maximum

      def visit_Arel_Predicates_Equality o
        @stack.push o
        call(o, :operand1) { |t| visit t }
        call(o, :operand2) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Value o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :value) { |t| visit t }
        @stack.pop
      end

      def visit_Array o
        @stack.push o
        o.each_with_index do |thing, i|
          @callstack.push i.to_s
          visit thing
          @callstack.pop
        end
        @stack.pop
      end

      def visit_Arel_Join o
        @stack.push o
        call(o, :relation1) { |t| visit t }
        call(o, :relation2) { |t| visit t }
        call(o, :predicates) { |t| visit t }
        @stack.pop
      end
      alias :visit_Arel_StringJoin :visit_Arel_Join
      alias :visit_Arel_InnerJoin :visit_Arel_Join

      def visit_Arel_Header o
        @stack.push o
        call(o, :to_ary) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Attribute o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :name) { |t| visit t }
        call(o, :ancestor) { |t| visit t }
        @stack.pop
      end
      alias :visit_Arel_Sql_Attributes_Integer :visit_Arel_Attribute
      alias :visit_Arel_Sql_Attributes_String :visit_Arel_Attribute
      alias :visit_Arel_Sql_Attributes_Time :visit_Arel_Attribute

      def visit_Arel_SqlLiteral o; end
      def visit_String o; end
      def visit_Fixnum o; end
      def visit_Symbol o; end
      def visit_Arel_Sql_Christener o; end
      def visit_Arel_Ascending o; end


      def visit_Arel_Table o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :name) { |t| visit t }
        call(o, :table_alias) { |t| visit t }
        call(o, :christener) { |t| visit t }
        call(o, :attributes) { |t| visit t }
        @stack.pop
      end

      def visit_Arel_Take o
        @stack.push o
        call(o, :taken) { |t| visit t }
        @stack.pop
        visit_Arel_Project o
      end

      def visit_Arel_Project o
        @stack.push o
        call(o, :relation) { |t| visit t }
        call(o, :christener) { |t| visit t }
        #call(o, :attributes) { |t| visit t }
        [:wheres, :groupings, :orders, :havings, :projections].each do |op|
          call(o, op) { |t| visit t }
        end
        @stack.pop
      end

      def visit_Arel_Where o
        visit_Arel_Project o
        @stack.push o
        call(o, :predicates) { |t| visit t }
        @stack.pop
      end

      def visit o
        return if ::Array === o && o.empty?
        return unless o
        return cycle(o) if @seen[o.object_id]

        @seen[o.object_id] = o

        case o
        when ::String
          name = "String: '#{o}'"
        when Symbol
          name = "Symbol: '#{o}'"
        when Numeric
          name = "Numeric: '#{o}'"
        else
          name = o.class.name
        end

        @nodes.push Node.new escape(name), o.object_id

        if last = @stack.last
          @edges << Edge.new(@callstack.last, last.object_id, o.object_id)
        end
        send "visit_#{o.class.name.gsub('::', '_')}".to_sym, o
      end

      def cycle o
        if last = @stack.last
          @edges << Edge.new(@callstack.last, last.object_id, o.object_id)
        end
      end

      def call o, sym
        @callstack.push sym
        yield o.send sym
        @callstack.pop
      end

      def escape string
        string.gsub('"', '\"')
      end

      def to_dot
        dot = <<-eodot
digraph "ARel" {
node [width=0.375,height=0.25,shape=box];
        eodot

        @nodes.each do |node|
          dot.concat <<-eonode
#{node.id} [label="#{node.name}"];
          eonode
        end
        @edges.each do |edge|
          dot.concat <<-eoedge
#{edge.left} -> #{edge.right} [label="#{edge.name}"];
          eoedge
        end
        dot + "}"
      end
    end
  end
end
