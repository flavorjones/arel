module Arel
  module Visitors
    class TreeConversion
      def initialize
        @projects = []
        @tables   = []
        @wheres   = []
        @sources  = []
        @joins    = []
        @orders   = []
        @offset   = nil
        @having   = nil
        @groups   = []
        @takes    = []
      end

      def accept object
        if $DEBUG
          viz = Arel::Visitors::Dot.new
          File.open(File.expand_path('~/h.dot'), 'wb') do |f|
            f.write viz.accept object
          end
        end

        visit object

        # If no columns were specified, use the table attributes
        if @projects.blank?
          column_sources = @sources.dup
          column_tables = []
          until column_sources.empty?
            source = column_sources.pop
            case source
            when InnerJoin
              column_sources << source.relation2
              column_sources << source.relation1
            else
              @projects += source.attributes
            end
          end
          @projects.uniq!
        end

        # SELECT <PROJECT> FROM <TABLE> WHERE <WHERE> LIMIT <TAKE>
        engine = @sources.first.engine

        Nodes::Select.new(
          @projects,
          @sources.reverse,
          @wheres,
          @groups,
          @having,
          @orders,
          @takes,
          @offset,
          engine
        )
      end

      private
      def visit object
        method = object.class.name.gsub '::', '_'
        send "visit_#{method}".to_sym, object
      end

      def visit_Arel_StringJoin o
        @sources << o
        visit o.relation1
      end

      def visit_Arel_Having o
        @having = o
        visit o.relation
      end

      def visit_Arel_Skip o
        @offset = o
        visit o.relation
      end

      def visit_Arel_Order o
        @orders << o
        visit o.relation
      end

      def visit_Arel_Group o
        @groups << o
        visit o.relation
      end

      def visit_Arel_Take o
        @takes << o
        visit o.relation
      end

      def visit_Arel_Where o
        @wheres << o
        visit o.relation
      end

      def visit_Arel_Project o
        @projects << o
        visit o.relation
      end

      def visit_Arel_Project o
        @projects << o
        visit o.relation
      end

      def visit_Arel_Lock o
        visit o.relation
      end

      def visit_Arel_Alias o
        @sources << o
      end

      def visit_Arel_Join o
        @sources << o
      end
      alias :visit_Arel_Table :visit_Arel_Join
      alias :visit_Arel_From :visit_Arel_Join
      alias :visit_Arel_InnerJoin :visit_Arel_Join
    end
  end
end