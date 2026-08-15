# frozen_string_literal: true

require_relative "base"
require_relative "../query_builder"
require_relative "../relation_hydrator"
require_relative "../concurrency"

module Kabk
  module Adapters
    # Sequel adapter for Kabk resources
    class SequelAdapter < Base
      # @param params [Hash] Request parameters (page, per_page, sort, filters).
      # @param context [Hash]
      # @return [Hash] Protocol response hash with success, data, meta
      def list(params, context: {})
        dataset = QueryBuilder.build(@resource, params)

        if dataset.respond_to?(:pagination_record_count)
          total = dataset.pagination_record_count
          page = dataset.current_page
          per_page = dataset.page_size
          last_page = dataset.page_count
          records = dataset.all
        else
          records = dataset.all
          total = records.size
          page = 1
          per_page = total
          last_page = 1
        end

        hydrated_records = RelationHydrator.hydrate(@resource, records)

        {
          success: true,
          data: hydrated_records,
          meta: {
            total: total,
            page: page,
            per_page: per_page,
            last_page: last_page
          }
        }
      end

      # @param id [Integer, String] Primary key
      # @param context [Hash]
      # @return [Hash] Protocol response hash with success, data
      # @raise [NotFoundError] If record doesn't exist
      def get(id, context: {})
        record = @resource.model_class[id]
        raise NotFoundError, "Record not found" unless record

        hydrated_records = RelationHydrator.hydrate(@resource, [record])

        {
          success: true,
          data: hydrated_records.first
        }
      end

      # @param attributes [Hash] Sanitized attributes
      # @param context [Hash]
      # @return [Hash] Protocol response hash with success, message, data
      # @raise [ApiError] If unique constraint violated
      def create(attributes, context: {})
        record = @resource.model_class.create(attributes)

        hydrated_records = RelationHydrator.hydrate(@resource, [record])

        {
          success: true,
          message: "Operation completed successfully",
          data: hydrated_records.first
        }
      rescue Sequel::UniqueConstraintViolation
        raise ApiError.new("Unique constraint violated", code: "CONFLICT", http_status: 409)
      end

      # @param id [Integer, String] Primary key
      # @param attributes [Hash] Sanitized attributes (with concurrency_field included if passed)
      # @param context [Hash]
      # @return [Hash] Protocol response hash with success, message, data
      # @raise [NotFoundError] If record doesn't exist
      # @raise [ApiError] If OCC fails or unique constraint violated
      def update(id, attributes, context: {})
        record = @resource.model_class[id]
        raise NotFoundError, "Record not found" unless record

        Concurrency.check!(@resource, record, attributes)

        c_field = @resource.concurrency_field&.to_sym
        attributes.delete(c_field) if c_field

        record.update(attributes)

        hydrated_records = RelationHydrator.hydrate(@resource, [record])

        {
          success: true,
          message: "Operation completed successfully",
          data: hydrated_records.first
        }
      rescue Sequel::UniqueConstraintViolation
        raise ApiError.new("Unique constraint violated", code: "CONFLICT", http_status: 409)
      end

      # @param id [Integer, String] Primary key
      # @param context [Hash]
      # @return [Hash] Protocol response hash indicating success
      # @raise [NotFoundError] If record doesn't exist
      def delete(id, context: {})
        record = @resource.model_class[id]
        raise NotFoundError, "Record not found" unless record

        record.destroy

        {
          success: true,
          message: "Record successfully deleted"
        }
      end

      # @param field_name [Symbol, String]
      # @param value [Object]
      # @param exclude_id [Integer, String, nil]
      # @return [Boolean]
      def exists?(field_name, value, exclude_id: nil)
        dataset = @resource.model_class.where(field_name.to_sym => value)
        if exclude_id
          pk = @resource.model_class.primary_key || :id
          dataset = dataset.exclude(pk.to_sym => exclude_id)
        end
        !dataset.empty?
      end
    end
  end
end
