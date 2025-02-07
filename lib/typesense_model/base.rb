module TypesenseModel
  class Base
    class_attribute :collection_name
    class_attribute :schema_definition

    class << self
      def collection_name(name = nil)
        self.collection_name = name if name
        self.collection_name ||= self.name.underscore.pluralize
      end

      def define_schema(&block)
        self.schema_definition = Schema.new
        schema_definition.instance_eval(&block)
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
      @attributes = attributes
    end

    def save
      response = if id
        client.collections[collection_name].documents[id].update(attributes)
      else
        client.collections[collection_name].documents.create(attributes)
      end
      
      @attributes = response
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