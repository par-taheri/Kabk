# frozen_string_literal: true

require "bundler/setup"
require "kabk"
require "sequel"
require "json"

# In-memory DB for tests
DB = Sequel.sqlite
DB.extension :pagination

DB.create_table :mock_articles do
  primary_key :id
  String :title
  String :content
  Integer :author_id
  DateTime :created_at
  DateTime :updated_at
end

class MockArticle < Sequel::Model; end

Kabk.register(name: "article", table: MockArticle) do
  title "Articles"
  concurrency_field "updated_at"
  
  field :id, type: :number, form_type: :number, primary_key: true
  field :title, type: :string, form_type: :text, required: true, validation: { min_length: 3 }
  field :content, type: :string, form_type: :textarea
  field :author_id, type: :number, form_type: :number # Simplified for testing, normally relation
  field :created_at, type: :datetime, form_type: :datetime, readonly: true
  field :updated_at, type: :datetime, form_type: :datetime, readonly: true
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    MockArticle.truncate
  end
end
