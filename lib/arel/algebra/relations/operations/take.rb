module Arel
  class Take < Compound
    attr_reader :taken

    def self.new relation, taken
      obj = allocate
      obj.send(:initialize, relation, taken)

      return obj unless Project === relation

      projections = relation.projections
      count       = relation.projections.first
      return obj unless projections.length == 1 && Count === count

      subquery = Nodes::Subquery.new Nodes::Select.new(
        [Project.new(relation.relation, ['1'])],
        [relation.relation],
        [],
        [],
        [],
        [obj]
      )
      count = Nodes::Count.new "*"
      Nodes::Select.new [count], [subquery], [], [], [], [], relation.relation.engine
    end

    def initialize relation, taken
      super(relation)
      @taken = taken
    end

    def externalizable?
      true
    end

    def eval
      unoperated_rows[0, taken]
    end
  end
end
