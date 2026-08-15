# frozen_string_literal: true

require_relative "validator"

module Kabk
  # Generic CRUD engine for any registered resource, agnostic to the underlying database
  class RestEngine
    # @param resource_name [String, Symbol]
    def initialize(resource_name)
      @resource = Registry.instance.get(resource_name)
      raise NotFoundError, "Resource not found" unless @resource

      @adapter = @resource.adapter
      raise StandardError, "Resource has no adapter configured" unless @adapter
    end

    # List resources with pagination, sorting, filtering.
    #
    # @param params [Hash] Request parameters (page, per_page, sort, filters).
    # @param context [Hash] Context provided by host framework.
    # @return [Hash] A standard protocol response hash with success, data, and meta properties.
    def list(params, context: {})
      @adapter.list(params, context: context)
    end

    # Get single resource by ID.
    #
    # @param id [Integer, String] The primary key of the record.
    # @param context [Hash] Context provided by host framework.
    # @return [Hash] A standard protocol response hash with success and data properties.
    # @raise [NotFoundError] If the record does not exist.
    def get(id, context: {})
      @adapter.get(id, context: context)
    end

    # Create a new resource. Executes lifecycle hooks, validates parameters, and delegates to the adapter.
    #
    # @param params [Hash] The raw input attributes from the request payload.
    # @param context [Hash] Context provided by host framework.
    # @return [Hash] A standard protocol response hash or an error hash if a hook/validation fails.
    def create(params, context: {})
      inject_audit_field(params, context, "created_by")
      @resource.hooks[:before_create]&.call(params, context)
      sanitized = Validator.validate_and_sanitize!(@resource, params)
      validate_uniqueness!(sanitized)
      result = @adapter.create(sanitized, context: context)

      @resource.hooks[:after_create]&.call(result[:data], context)
      result
    rescue ApiError => e
      e.to_h
    end

    # Update an existing resource. Executes lifecycle hooks and validates Optimistic Concurrency Control (OCC).
    #
    # @param id [Integer, String] The primary key of the record.
    # @param params [Hash] The updated attributes from the request payload.
    # @param context [Hash] Context provided by host framework.
    # @return [Hash] A standard protocol response hash or an error hash if a hook/validation fails.
    def update(id, params, context: {})
      inject_audit_field(params, context, "updated_by")
      @resource.hooks[:before_update]&.call(id, params, context)
      sanitized = Validator.validate_and_sanitize!(@resource, params, is_update: true)
      validate_uniqueness!(sanitized, exclude_id: id)
      result = @adapter.update(id, sanitized, context: context)

      @resource.hooks[:after_update]&.call(result[:data], context)
      result
    rescue ApiError => e
      e.to_h
    end

    # Delete a resource by ID. Executes lifecycle hooks and delegates to the adapter.
    #
    # @param id [Integer, String] The primary key of the record.
    # @param context [Hash] Context provided by host framework.
    # @return [Hash] A standard protocol response hash indicating success or an error hash if a hook fails.
    def delete(id, context: {})
      @resource.hooks[:before_delete]&.call(id, context)
      result = @adapter.delete(id, context: context)

      @resource.hooks[:after_delete]&.call(id, context)
      result
    rescue ApiError => e
      e.to_h
    end

    private

    def inject_audit_field(params, context, field_name)
      return unless @resource.audit_fields&.map(&:to_s)&.include?(field_name)

      user_id = context[:current_user_id] || context["current_user_id"]
      params[field_name] = user_id if user_id
    end

    def validate_uniqueness!(sanitized, exclude_id: nil)
      errors = {}

      @resource.fields.each do |field|
        rules = field.validation
        next unless rules && (rules[:unique] == true || rules["unique"] == true)

        field_sym = field.name.to_sym
        field_str = field.name.to_s
        next unless sanitized.key?(field_sym) || sanitized.key?(field_str)

        value = sanitized.key?(field_sym) ? sanitized[field_sym] : sanitized[field_str]
        next if value.nil?

        if @adapter.exists?(field_sym, value, exclude_id: exclude_id)
          msg = rules[:custom_message] || rules["custom_message"] || "Already taken"
          errors[field_str] = [msg]
        end
      end

      raise ValidationError.new(fields: errors) unless errors.empty?
    end
  end
end
