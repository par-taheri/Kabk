# frozen_string_literal: true

module Kabk
  # Base error class for Kabk configuration errors
  class Error < StandardError; end

  # Error raised when a resource field definition is missing required attributes
  class InvalidFieldError < Error; end

  # DSL builder for configuring resources and their fields
  class ResourceBuilder
    def initialize(resource)
      @resource = resource
    end

    # Delegate dynamic attribute setting (e.g. title, icon, plural_name)
    def method_missing(method_name, *args, **kwargs, &)
      if @resource.respond_to?("#{method_name}=")
        value = if kwargs.any? && args.empty?
                  kwargs
                else
                  args.first
                end
        @resource.send("#{method_name}=", value)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @resource.respond_to?("#{method_name}=") || super
    end

    # Define a field with attributes
    def field(name, type:, form_type:, **attributes)
      # Validate required keys per spec
      raise InvalidFieldError, "Field '#{name}' is missing 'type'" unless type
      raise InvalidFieldError, "Field '#{name}' is missing 'form_type'" unless form_type

      # Extract label, if not provided, default to titleized name
      label = attributes.delete(:label)
      if label.nil?
        label = attributes.slice(:fa, :en)
        label = name.to_s.capitalize.tr("_", " ") if label.empty?
        attributes.reject! { |k, _v| %i[fa en].include?(k) }
      end

      f = Field.new(name: name, type: type, form_type: form_type, label: label, **attributes)
      @resource.fields << f
    end

    # Configure permissions explicitly
    def permissions(**perms)
      @resource.permissions.merge!(perms)
    end

    # --- Lifecycle Hooks ---

    # Registers a callback executed before the record is created.
    # @yield [params, context] The incoming parameters and host context.
    def before_create(&block)
      @resource.hooks[:before_create] = block
    end

    # Registers a callback executed after the record is created.
    # @yield [record, context] The newly created record hash and host context.
    def after_create(&block)
      @resource.hooks[:after_create] = block
    end

    # Registers a callback executed before the record is updated.
    # @yield [id, params, context] The record ID, incoming parameters, and host context.
    def before_update(&block)
      @resource.hooks[:before_update] = block
    end

    # Registers a callback executed after the record is updated.
    # @yield [record, context] The updated record hash and host context.
    def after_update(&block)
      @resource.hooks[:after_update] = block
    end

    # Registers a callback executed before the record is deleted.
    # @yield [id, context] The record ID and host context.
    def before_delete(&block)
      @resource.hooks[:before_delete] = block
    end

    # Registers a callback executed after the record is deleted.
    # @yield [id, context] The deleted record ID and host context.
    def after_delete(&block)
      @resource.hooks[:after_delete] = block
    end
  end
end
