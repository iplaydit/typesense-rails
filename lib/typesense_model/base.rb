module TypesenseModel
  class Base
    class << self
      attr_accessor :_collection_name, :_schema_definition

      def collection_name(name = nil)
        if name
          @_collection_name = name
        else
          @_collection_name ||= self.name.underscore.pluralize
        end
      end

      def define_schema(&block)
        @_schema_definition = Schema.new
        @_schema_definition.instance_eval(&block)
      end

      def schema_definition
        @_schema_definition
      end

      def create(attributes = {})
        new(attributes).save
      end

      def find(id)
        response = client.collections[collection_name].documents[id].retrieve
        new(response)
      rescue Typesense::Error::ObjectNotFound
        nil
      end

      def search(query, options = {})
        Search.new(self, query, options).execute
      end

      private

      def client
        TypesenseModel.configuration.client
      end
    end

    attr_accessor :attributes

    def initialize(attributes = {})
      @attributes = attributes.transform_keys(&:to_s)
    end

    def save
      response = if id
        self.class.send(:client).collections[self.class.collection_name].documents[id].update(attributes)
      else
        self.class.send(:client).collections[self.class.collection_name].documents.create(attributes)
      end
      
      @attributes = response.transform_keys(&:to_s)
      self
    end

    def id
      attributes['id']
    end

    private

    def client
      self.class.send(:client)
    end
  end
end 