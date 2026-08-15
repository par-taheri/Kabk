# frozen_string_literal: true

module Kabk
  # Represents field/column metadata
  class Field
    # @return [String] The technical name of the field (e.g., "created_at").
    attr_accessor :name
    # @return [String] The human-readable label for the field.
    attr_accessor :label
    # @return [Symbol] The underlying data type (:string, :number, :boolean, :date, :datetime, :file, :relation).
    attr_accessor :type
    # @return [Symbol] The frontend input component type (e.g., :text, :switch, :date, :image_single).
    attr_accessor :form_type
    # @return [Symbol] The calendar system to use if type is date/datetime (e.g., :jalali, :gregorian).
    attr_accessor :calendar
    # @return [Boolean] Indicates if this field is the primary key.
    attr_accessor :primary_key
    # @return [Boolean] Indicates if this field can be null.
    attr_accessor :nullable
    # @return [Symbol] UI hint for how to display the value (e.g., :badge, :thumbnail, :boolean_icon).
    attr_accessor :display_as
    # @return [Integer] Bootstrap grid column width (1 to 12).
    attr_accessor :col_width
    # @return [Integer] The explicit ordering weight for rendering.
    attr_accessor :order
    # @return [Boolean] Indicates if this field is mandatory in forms.
    attr_accessor :required
    # @return [Boolean] Indicates if this field is read-only.
    attr_accessor :readonly
    # @return [Boolean] If true, hides the field in data tables.
    attr_accessor :hidden_in_table
    # @return [Boolean] If true, hides the field in forms.
    attr_accessor :hidden_in_form
    # @return [Boolean] If true, wraps this field in an accordion section.
    attr_accessor :accordion
    # @return [Integer] For textarea form_type, specifies the number of rows.
    attr_accessor :rows
    # @return [Array, Hash] Hardcoded select options if applicable.
    attr_accessor :options
    # @return [Object] The default value for the field.
    attr_accessor :default_value
    # @return [Hash] Configures field dependency visibility (e.g., { field: "published", value: true }).
    attr_accessor :depends_on
    # @return [Hash] Server-side validation rules (e.g., { min_length: 5, unique: true }).
    attr_accessor :validation
    # @return [Hash] Relational metadata (e.g., { resource: "user", cardinality: "many_to_one", ... }).
    attr_accessor :relation
    # @return [Hash] Configuration for file uploads.
    attr_accessor :upload_config

    def initialize(name:, **attributes)
      @name = name.to_s
      @primary_key = false
      @nullable = false
      @col_width = 12
      @required = false
      @readonly = false
      @hidden_in_table = false
      @hidden_in_form = false
      @accordion = false

      attributes.each do |k, v|
        send("#{k}=", v) if respond_to?("#{k}=")
      end
    end

    def to_h
      hash = {
        name: @name,
        label: @label,
        type: @type,
        form_type: @form_type
      }

      hash[:calendar] = @calendar if @calendar
      hash[:primary_key] = @primary_key if @primary_key
      hash[:nullable] = @nullable unless @nullable.nil?
      hash[:display_as] = @display_as if @display_as
      hash[:col_width] = @col_width if @col_width
      hash[:order] = @order if @order
      hash[:required] = @required if @required
      hash[:readonly] = @readonly if @readonly
      hash[:hidden_in_table] = @hidden_in_table if @hidden_in_table
      hash[:hidden_in_form] = @hidden_in_form if @hidden_in_form
      hash[:accordion] = @accordion if @accordion
      hash[:rows] = @rows if @rows
      hash[:options] = @options if @options
      hash[:default_value] = @default_value unless @default_value.nil?
      hash[:depends_on] = @depends_on if @depends_on
      hash[:validation] = @validation if @validation
      hash[:relation] = @relation if @relation
      hash[:upload_config] = @upload_config if @upload_config

      hash
    end
  end
end
