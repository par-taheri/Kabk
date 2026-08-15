# frozen_string_literal: true

require_relative "errors"

module Kabk
  # Handles input sanitization (strong parameters) and validation
  class Validator
    # Sanitizes input parameters against defined fields and validates them
    # @param resource [Kabk::Resource]
    # @param params [Hash] Request payload
    # @param is_update [Boolean] Is this a PUT/update request?
    # @return [Hash] Sanitized parameters ready for the database adapter
    def self.validate_and_sanitize!(resource, params, is_update: false)
      sanitized = {}
      errors = {}

      resource.fields.each do |field|
        next if field.primary_key || field.readonly

        key_sym = field.name.to_sym
        key_str = field.name.to_s
        has_key = params.key?(key_sym) || params.key?(key_str)
        value = params.key?(key_sym) ? params[key_sym] : params[key_str]

        field_errors = validate_field(field, value, has_key, is_update)
        errors[key_str] = field_errors unless field_errors.empty?

        sanitized[key_sym] = value if has_key
      end

      # Ensure the concurrency field is included for OCC validation.
      if resource.concurrency_field
        c_field = resource.concurrency_field
        sanitized[c_field.to_sym] = params[c_field.to_sym] || params[c_field.to_s] if params.key?(c_field.to_sym) || params.key?(c_field.to_s)
      end

      raise ValidationError.new(fields: errors) unless errors.empty?

      sanitized
    end

    def self.validate_field(field, value, has_key, is_update)
      rules = field.validation.is_a?(Hash) ? field.validation : nil

      if field.required
        return [resolve_message(rules, "This field is required")] if !has_key && !is_update
        return [resolve_message(rules, "This field is required")] if has_key && (value.nil? || value.to_s.strip.empty?)
      end

      return [] unless has_key && !value.nil? && rules

      collect_rule_errors(field, rules, value)
    end

    def self.collect_rule_errors(field, rules, value)
      errs = []

      if field.type.to_s == "string" && value.is_a?(String)
        len_err = validate_string_length(rules, value)
        errs << len_err if len_err
      end

      if (rules[:pattern] || rules["pattern"]) && value.is_a?(String)
        pat_err = validate_pattern(rules, value)
        errs << pat_err if pat_err
      end

      if field.type.to_s == "number"
        num_err = validate_numeric_range(rules, value)
        errs << num_err if num_err
      end

      errs
    end

    def self.validate_string_length(rules, value)
      min_len = rules[:min_length] || rules["min_length"]
      max_len = rules[:max_length] || rules["max_length"]

      return resolve_message(rules, "Minimum length is #{min_len}") if min_len && value.length < min_len
      return resolve_message(rules, "Maximum length is #{max_len}") if max_len && value.length > max_len

      nil
    end

    def self.validate_pattern(rules, value)
      pattern = rules[:pattern] || rules["pattern"]
      return nil unless pattern

      regex = pattern.is_a?(Regexp) ? pattern : Regexp.new(pattern.to_s)
      return nil if regex.match?(value)

      resolve_message(rules, "Does not match the required format")
    end

    def self.validate_numeric_range(rules, value)
      min = rules[:min] || rules["min"]
      max = rules[:max] || rules["max"]
      return nil unless min || max

      num = parse_numeric(value)
      return nil unless num

      return resolve_message(rules, "Minimum value is #{min}") if min && num < min
      return resolve_message(rules, "Maximum value is #{max}") if max && num > max

      nil
    end

    def self.parse_numeric(value)
      return value if value.is_a?(Numeric)
      return nil unless value.is_a?(String) && value =~ /\A-?\d+(\.\d+)?\z/

      value.include?(".") ? value.to_f : value.to_i
    end

    def self.resolve_message(rules, default_message)
      rules&.dig(:custom_message) || rules&.dig("custom_message") || default_message
    end
  end
end
