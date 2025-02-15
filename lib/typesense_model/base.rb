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

      # Retrieve collection details
      def retrieve_collection
        return nil unless collection_exists?
        client.collections[collection_name].retrieve
      end

      # Get collection stats
      def collection_stats
        return nil unless collection_exists?
        client.collections[collection_name].stats
      end

      # Get number of documents in collection
      def count
        collection_stats&.dig('num_documents') || 0
      end

      # Import multiple records
      # @return [Hash] { success: Integer, failed: Integer }
      def import(documents, options = {})
        response = client.collections[collection_name]
          .documents
          .import(documents, options)

        results = response.each_with_object({ success: 0, failed: 0 }) do |result, counts|
          result['success'] ? counts[:success] += 1 : counts[:failed] += 1
        end

        results
      end

      # Import records from an ActiveRecord model
      # @param model_class [Class] The ActiveRecord model class to import from
      # @param batch_size [Integer] Number of records to fetch per batch
      # @param transform_method [Symbol, Proc] Method or Proc to transform records
      # @param import_options [Hash] Options to pass to the import method
      # @return [Hash] { success: Integer, failed: Integer }
      def import_from_model(model_class, batch_size, transform_method = :as_json, import_options = {})
        total_results = { success: 0, failed: 0 }

        transformer = transform_method.is_a?(Proc) ? transform_method : ->(record) { record.send(transform_method) }

        model_class.find_in_batches(batch_size: batch_size) do |batch|
          documents = batch.map(&transformer)
          results = import(documents, import_options)
          
          total_results[:success] += results[:success]
          total_results[:failed] += results[:failed]
        end

        total_results
      end

      # Delete a record by ID
      def delete(id)
        client.collections[collection_name]
          .documents[id]
          .delete
      rescue Typesense::Error::ObjectNotFound
        false
      end

      # Delete multiple records by query
      def delete_by(filter_by)
        client.collections[collection_name]
          .documents
          .delete({ filter_by: filter_by })
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
      response = self.class.send(:client).collections[self.class.collection_name].documents.upsert(attributes)
      
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
      
      nil
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

    # Instance method to delete the current record
    def delete
      return false unless id
      
      response = self.class.delete(id)
      !response.nil?
    end
  end
end 