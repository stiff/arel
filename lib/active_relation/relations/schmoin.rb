module ActiveRelation
  class Schmoin < Relation
    attr_reader :join_sql, :relation1, :relation2, :predicates
    delegate :table_sql, :to => :relation1

    def initialize(join_sql, relation1, relation2, *predicates)
      @join_sql, @relation1, @relation2, @predicates = join_sql, relation1, relation2, predicates
    end

    def ==(other)
      predicates == other.predicates and
        ((relation1 == other.relation1 and relation2 == other.relation2) or
        (relation2 == other.relation1 and relation1 == other.relation2))
    end

    def qualify
      Schmoin.new(join_sql, relation1.qualify, relation2.qualify, *predicates.collect(&:qualify))
    end

    protected
    def joins
      [relation1.joins, relation2.joins, join].compact.join(" ")
    end

    def selects
      relation1.send(:selects) + relation2.send(:selects)
    end
    
    # this is magick!!!
    def projections
      relation1.projections + relation2.attributes
    end

    def attribute(name)
      relation1[name] || relation2[name]
    end

    private
    def join
      "#{join_sql} #{relation2.to_sql(Sql::Aggregation.new)} ON #{predicates.collect { |p| p.to_sql(Sql::Predicate.new) }.join(' AND ')}"
    end
  end
end