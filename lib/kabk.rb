# frozen_string_literal: true

require_relative "kabk/version"
require_relative "kabk/registry"
require_relative "kabk/resource"
require_relative "kabk/field"
require_relative "kabk/resource_builder"
require_relative "kabk/schema_renderer"
require_relative "kabk/errors"
require_relative "kabk/concurrency"
require_relative "kabk/validator"
require_relative "kabk/query_builder"
require_relative "kabk/relation_hydrator"
require_relative "kabk/rest_engine"
require_relative "kabk/upload_handler"
require_relative "kabk/adapters/base"
require_relative "kabk/adapters/sequel_adapter"

# Core namespace and entrypoint for Kabk
module Kabk
  # Register a new model as a resource
  #
  # @param name [String, Symbol] The unique identifier for the resource
  # @param table [Class] The Model class (e.g. Sequel::Model)
  # @param adapter [Kabk::Adapters::Base] Optional explicit adapter instance
  # @yield Block evaluated in the context of a ResourceBuilder
  def self.register(name:, table:, adapter: nil, &block)
    resource = Resource.new(name: name, model_class: table)
    builder = ResourceBuilder.new(resource)
    builder.instance_eval(&block) if block_given?

    # Fallbacks per protocol
    resource.plural_name ||= "#{name}s"
    resource.title ||= resource.plural_name.capitalize
    resource.icon ||= "Database"
    resource.api_path ||= "/api/admin/#{resource.plural_name}"

    # Determine and assign adapter
    if adapter
      resource.adapter = adapter
    elsif defined?(Sequel::Model) && table < Sequel::Model
      resource.adapter = Adapters::SequelAdapter.new(resource)
    else
      raise ArgumentError, "Could not determine appropriate adapter for #{table}. Please provide an explicit adapter."
    end

    Registry.instance.register(resource)
    resource
  end
end
