module Arel
  class Project < Compound
    attr_reader :projections, :attributes, :christener

    def initialize(relation, projections)
      super(relation)
      @projections = projections.map { |p|
        case p
        when Project
          Nodes::Subquery.new Visitors::Sql2.linked_list_to_tree(p), relation
        else
          p.bind(relation)
        end
      }
      @christener = Sql::Christener.new
      @attributes = Header.new(projections.map { |x| x.bind(self) })
    end

    def externalizable?
      attributes.any? { |a| a.respond_to?(:aggregation?) && a.aggregation? } || relation.externalizable?
    end

    def eval
      unoperated_rows.collect { |r| r.slice(*projections) }
    end
  end
end
