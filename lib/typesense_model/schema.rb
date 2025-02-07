module TypesenseModel
  class Schema
    attr_reader :fields, :collection_name

    def initialize(collection_name = nil)
      @fields = []
      @collection_name = collection_name
    end

    def field(name, type, options = {})
      @fields << {
        name: name.to_s,
        type: type.to_s,
        facet: options[:facet] || false,
        optional: options[:optional] || false,
        index: options[:index].nil? ? true : options[:index]
      }
    end

    def to_hash
      {
        name: @collection_name,
        fields: @fields,
        default_sorting_field: default_sorting_field
      }.compact
    end

    private

    def default_sorting_field
      @fields.find { |f| f[:name] == 'id' }&.dig(:name)
    end
  end
end 