# frozen_string_literal: true

require "concurrent-ruby"

module Kabk
  # Thread-safe registry for managing registered resources
  class Registry
    # @return [Registry]
    def self.instance
      @instance ||= new
    end

    def initialize
      @resources = Concurrent::Map.new
    end

    # Register a new resource
    # @param resource [Kabk::Resource]
    def register(resource)
      @resources[resource.name.to_sym] = resource
    end

    # Retrieve a resource by name
    # @param name [Symbol, String]
    # @return [Kabk::Resource, nil]
    def get(name)
      @resources[name.to_sym]
    end

    # Get all registered resources
    # @return [Array<Kabk::Resource>]
    def all
      @resources.values
    end

    # Clears all registered resources from the registry
    def clear
      @resources.clear
    end
  end
end
