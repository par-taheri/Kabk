# frozen_string_literal: true

require_relative "errors"

module Kabk
  # Handles Optimistic Concurrency Control (OCC)
  class Concurrency
    # Check if the provided version matches the database state
    # @param resource [Kabk::Resource]
    # @param current_record [Object] The existing record in the database
    # @param submitted_params [Hash] The payload from the client
    # @raise [Kabk::ConcurrencyConflictError] if there is a mismatch
    def self.check!(resource, current_record, submitted_params)
      return unless resource.concurrency_field

      field = resource.concurrency_field.to_sym
      return unless submitted_params.key?(field) || submitted_params.key?(field.to_s)

      client_version = submitted_params[field] || submitted_params[field.to_s]
      db_version = current_record.send(field)

      # Handle Time object comparison by converting DB to ISO8601 (which is what the client sends)
      db_version_str = db_version.is_a?(Time) || db_version.respond_to?(:iso8601) ? db_version.iso8601 : db_version.to_s

      return unless client_version.to_s != db_version_str

      raise ConcurrencyConflictError, "Record has been updated by another user."
    end
  end
end
