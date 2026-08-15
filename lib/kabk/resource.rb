# frozen_string_literal: true

module Kabk
  # Metadata value object for a registered resource
  class Resource
    # @return [String] The technical singular name of the resource (e.g., "news_item").
    attr_accessor :name
    # @return [String] The plural name used in routing (e.g., "news").
    attr_accessor :plural_name
    # @return [Hash] Localization hash for the resource title (e.g., { fa: "اخبار", en: "News" }).
    attr_accessor :title
    # @return [String] The identifier of the icon to render in the sidebar.
    attr_accessor :icon
    # @return [String] The base API path where the resource is mounted (e.g., "/api/admin/news").
    attr_accessor :api_path
    # @return [Boolean] Whether to display this resource in the admin sidebar menu.
    attr_accessor :display_in_sidebar
    # @return [String] The menu group category for this resource.
    attr_accessor :group
    # @return [Integer] The explicit ordering weight in the sidebar.
    attr_accessor :order
    # @return [String] The default sort column and direction (e.g., "-created_at").
    attr_accessor :default_sort
    # @return [Integer] Default number of records per page for pagination.
    attr_accessor :per_page_default
    # @return [Array<String>] List of field names that support full-text search.
    attr_accessor :searchable_fields
    # @return [Array<String>] List of field names that can be sorted by.
    attr_accessor :sortable_fields
    # @return [Array<String>] List of field names that can be filtered on.
    attr_accessor :filterable_fields
    # @return [String] The field used for Optimistic Concurrency Control (OCC), usually "updated_at".
    attr_accessor :concurrency_field
    # @return [Array<String>] Configures standard audit fields (created_at, updated_at).
    attr_accessor :audit_fields
    # @return [Hash] The baseline CRUD permissions (can_view, can_edit, etc).
    attr_accessor :permissions
    # @return [Array<Kabk::Field>] The array of registered field objects.
    attr_accessor :fields
    # @return [Class] The underlying ORM Model class (e.g., Sequel::Model).
    attr_accessor :model_class
    # @return [Kabk::Adapters::Base] The adapter instance for this resource.
    attr_accessor :adapter
    # @return [Hash] Configured lifecycle hooks.
    attr_accessor :hooks

    def initialize(name:, model_class:)
      @name = name.to_s
      @model_class = model_class
      @fields = []
      @hooks = {}
      @display_in_sidebar = true
      @per_page_default = 15
      @permissions = {
        can_view: true,
        can_insert: true,
        can_edit: true,
        can_delete: true,
        can_export: true
      }
    end

    def to_h
      hash = {
        name: @name,
        plural_name: @plural_name,
        title: @title,
        icon: @icon,
        api_path: @api_path
      }

      hash[:display_in_sidebar] = @display_in_sidebar unless @display_in_sidebar.nil?
      hash[:group] = @group if @group
      hash[:order] = @order if @order
      hash[:default_sort] = @default_sort if @default_sort
      hash[:per_page_default] = @per_page_default if @per_page_default
      hash[:searchable_fields] = @searchable_fields if @searchable_fields
      hash[:sortable_fields] = @sortable_fields if @sortable_fields
      hash[:filterable_fields] = @filterable_fields if @filterable_fields
      hash[:concurrency_field] = @concurrency_field if @concurrency_field
      hash[:audit_fields] = @audit_fields if @audit_fields
      hash[:permissions] = @permissions if @permissions
      hash[:fields] = @fields.map(&:to_h)

      hash
    end
  end
end
