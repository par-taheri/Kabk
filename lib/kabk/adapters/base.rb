# frozen_string_literal: true

module Kabk
  module Adapters
    # Abstract base class for ORM Adapters
    class Base
      attr_reader :resource

      def initialize(resource)
        @resource = resource
      end

      # @param params [Hash] Request parameters (page, per_page, sort, filters).
      # @param context [Hash] Context provided by host framework (e.g. current_user).
      def list(params, context: {})
        raise NotImplementedError, "#{self.class} must implement #list"
      end

      # @param id [Integer, String] Primary key
      # @param context [Hash] Context provided by host framework (e.g. current_user).
      def get(id, context: {})
        raise NotImplementedError, "#{self.class} must implement #get"
      end

      # @param attributes [Hash] Sanitized attributes
      # @param context [Hash] Context provided by host framework (e.g. current_user).
      def create(attributes, context: {})
        raise NotImplementedError, "#{self.class} must implement #create"
      end

      # @param id [Integer, String] Primary key
      # @param attributes [Hash] Sanitized attributes
      # @param context [Hash] Context provided by host framework (e.g. current_user).
      def update(id, attributes, context: {})
        raise NotImplementedError, "#{self.class} must implement #update"
      end

      # @param id [Integer, String] Primary key
      # @param context [Hash] Context provided by host framework (e.g. current_user).
      def delete(id, context: {})
        raise NotImplementedError, "#{self.class} must implement #delete"
      end

      # @param field_name [Symbol, String] Field/column name to check
      # @param value [Object] Value to check
      # @param exclude_id [Integer, String, nil] Optional ID to exclude from check
      # @return [Boolean]
      def exists?(field_name, value, exclude_id: nil)
        raise NotImplementedError, "#{self.class} must implement #exists?"
      end
    end
  end
end
