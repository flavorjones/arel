module Arel
  class Alias < Compound
    include Recursion::BaseCase

    attr_reader :table

    def initialize relation
      @table = relation
      super
    end

    def name
      @table.name_for self
    end

    def eval
      unoperated_rows
    end
  end
end
