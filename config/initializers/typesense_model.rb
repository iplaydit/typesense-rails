TypesenseModel.configure do |config|
  config.api_key = ENV['TYPESENSE_API_KEY']
  config.host = ENV['TYPESENSE_HOST'] || 'localhost'
  config.port = ENV['TYPESENSE_PORT'] || 8108
  config.protocol = ENV['TYPESENSE_PROTOCOL'] || 'http'
end

# Create collections for all your TypesenseModel classes
# Be sure to only include models that are ready for collection creation
# [Product].each(&:create_collection) 