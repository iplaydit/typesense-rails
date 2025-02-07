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

      # Create the collection in Typesense
      def create_collection(force = false)
        delete_collection if force
        return if collection_exists? 
        
        schema = schema_definition.to_hash.merge(
          name: collection_name
        )

        client.collections.create(schema)
      end

      # Delete the collection from Typesense
      def delete_collection
        client.collections[collection_name].delete if collection_exists?
      end

      # Check if collection exists
      def collection_exists?
        client.collections[collection_name].retrieve
        true
      rescue Typesense::Error::ObjectNotFound
        false
      end

      # Update the collection schema in Typesense
      def update_collection
        return create_collection unless collection_exists?

        schema = schema_definition.to_hash.merge(
          name: collection_name
        )

        client.collections[collection_name].update(schema)
      end

      # Create or update collection
      def create_or_update_collection
        collection_exists? ? update_collection : create_collection
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

    def method_missing(method_name, *args)
      attribute_name = method_name.to_s
      
      # Handle setters (e.g., name=)
      if attribute_name.end_with?('=')
        attribute_name = attribute_name.chop # Remove the '=' from the end
        return set_attribute(attribute_name, args.first)
      end
      
      # Handle getters (e.g., name)
      if attributes.key?(attribute_name)
        return attributes[attribute_name]
      end
      
      super
    end

    def respond_to_missing?(method_name, include_private = false)
      attribute_name = method_name.to_s
      return true if attribute_name.end_with?('=') && attributes.key?(attribute_name.chop)
      return true if attributes.key?(attribute_name)
      super
    end

    private

    def set_attribute(name, value)
      attributes[name.to_s] = value
    end

    def client
      self.class.send(:client)
    end
  end
end 