# TypesenseModel

A Ruby gem that provides an ActiveModel-like interface for Typesense search engine.

## Installation

Add to your Gemfile:
gem 'typesense_model'

Or install directly:
$ gem install typesense_model

## Configuration

Initialize Typesense connection:

TypesenseModel.configure do |config|
  config.api_key = 'your_api_key'
  config.host = 'localhost'
  config.port = 8108
  config.protocol = 'http'
end

## Basic Usage

Define your model:

class Product < TypesenseModel::Base
  collection_name :products

  define_schema do
    field :id, :string
    field :name, :string
    field :price, :float
    field :categories, :string[], facet: true
  end
end

Create records:
product = Product.create(
  name: 'iPhone 12',
  price: 999.99,
  categories: ['Electronics', 'Phones']
)

Search records:
results = Product.search('iPhone', 
  query_by: 'name',
  filter_by: 'price:< 1000'
)

Find by ID:
product = Product.find('product_id')

## Development

After checking out the repo:
1. Run bundle install to install dependencies
2. Run rake spec to run the tests
3. Create a branch for your changes
4. Submit a pull request

## License

Available as open source under the MIT License.
Copyright (c) 2025 I Play'd It BV

