module TypesenseModel
  class Search
    def initialize(model_class, query, options = {})
      @model_class = model_class
      @query = query
      @options = options
    end

    def execute
      search_parameters = {
        q: @query,
        query_by: @options[:query_by] || default_queryable_fields,
        per_page: @options[:per_page] || 10,
        page: @options[:page] || 1
      }.merge(@options.except(:query_by, :per_page, :page))

      response = @model_class.send(:client)
        .collections[@model_class.collection_name]
        .documents
        .search(search_parameters)

      SearchResults.new(response, @model_class)
    end

    private

    def default_queryable_fields
      @model_class.schema_definition.fields
        .select { |f| f[:index] }
        .select { |f| f[:type] == 'string' }
        .reject { |f| f[:name] == 'id' }
        .map { |f| f[:name] }
        .join(',')
    end
  end

  class SearchResults
    include Enumerable

    attr_reader :raw_response

    def initialize(response, model_class)
      @raw_response = response
      @model_class = model_class
    end

    def each(&block)
      hits.each do |hit|
        yield @model_class.new(hit['document'])
      end
    end

    def map(&block)
      hits.map do |hit|
        block.call(@model_class.new(hit['document']))
      end
    end

    def hits
      @raw_response['hits'] || []
    end

    def size
      total_hits
    end

    def total_hits
      @raw_response['found'] || 0
    end
    # PAGY COMPATIBILITY
    def count(_)
      total_hits
    end
    def offset(_)
      self
    end
    def limit(_)
      self
    end

    def facets
      @raw_response['facet_counts'] || []
    end

    # Get a specific facet by field name
    def facet(field_name)
      facets.find { |f| f['field_name'] == field_name.to_s }
    end

    # Get facet values for a specific field
    def facet_values(field_name)
      facet(field_name)&.fetch('counts', []) || []
    end
  end
end 