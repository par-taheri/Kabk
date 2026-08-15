# frozen_string_literal: true

require_relative "registry"

module Kabk
  # Hydrates `<field>_display` for relation fields to prevent N+1 queries.
  class RelationHydrator
    # Hydrates a collection of records in-memory or via SQL joins/eager loading
    # @param resource [Kabk::Resource]
    # @param records [Array<Hash>, Array<Sequel::Model>]
    # @return [Array<Hash>] Hydrated records as hashes
    def self.hydrate(resource, records)
      return [] if records.empty?

      # Convert all records to hashes immediately if they are models
      record_hashes = records.map { |r| r.is_a?(Hash) ? r.dup : r.values }

      relation_fields = resource.fields.select { |f| f.type == "relation" && f.relation }

      relation_fields.each do |field|
        rel_meta = field.relation
        target_resource = Registry.instance.get(rel_meta["resource"] || rel_meta[:resource])
        next unless target_resource

        target_model = target_resource.model_class
        value_field = (rel_meta["value_field"] || rel_meta[:value_field]).to_sym
        label_field = (rel_meta["label_field"] || rel_meta[:label_field]).to_sym
        display_key = (rel_meta["display_key"] || rel_meta[:display_key] || "#{field.name}_display").to_sym
        cardinality = rel_meta["cardinality"] || rel_meta[:cardinality] || "many_to_one"
        field_sym = field.name.to_sym

        # Extract all keys to load
        keys_to_load = record_hashes.flat_map do |rh|
          val = rh[field_sym]
          if val.is_a?(String) && cardinality == "many_to_many" && val.is_a?(String)
            # Handle JSON or comma-separated string values.
            val = begin
              JSON.parse(val)
            rescue StandardError
              val.split(",")
            end
          end
          val
        end.flatten.compact.uniq

        next if keys_to_load.empty?

        # Load relation map.
        # Example: SELECT id, full_name FROM users WHERE id IN (...)
        target_data = target_model.where(value_field => keys_to_load).select(value_field, label_field).all
        target_map = target_data.each_with_object({}) do |row, map|
          map[row[value_field]] = row[label_field]
          map[row[value_field].to_s] = row[label_field] # allow string keys too
        end

        # Map back to records
        record_hashes.each do |rh|
          val = rh[field_sym]
          if cardinality == "many_to_many"
            arr = if val.is_a?(Array)
                    val
                  else
                    begin
                      JSON.parse(val.to_s)
                    rescue StandardError
                      val.to_s.split(",")
                    end
                  end
            rh[display_key] = arr.map { |v| target_map[v] }.compact if arr
          elsif val
            rh[display_key] = target_map[val]
          end
        end
      end

      # Format dates to ISO8601 per standard protocol.
      format_dates!(resource, record_hashes)

      record_hashes
    end

    def self.format_dates!(resource, record_hashes)
      date_fields = resource.fields.select { |f| %w[date datetime].include?(f.type) }.map(&:name).map(&:to_sym)

      record_hashes.each do |rh|
        # Include standard audit/concurrency fields if present and not explicitly defined as fields
        %i[created_at updated_at].each do |ts|
          if rh[ts].respond_to?(:iso8601)
            rh[ts] = rh[ts].iso8601
          elsif rh[ts].is_a?(Time) || rh[ts].is_a?(Date) || rh[ts].is_a?(DateTime)
            # Fallback formatting if it responds to strftime
            rh[ts] = rh[ts].strftime("%Y-%m-%dT%H:%M:%S.%LZ")
          end
        end

        date_fields.each do |df|
          val = rh[df]
          if val.respond_to?(:iso8601)
            rh[df] = val.iso8601
          elsif val.is_a?(Time) || val.is_a?(Date) || val.is_a?(DateTime)
            rh[df] = val.strftime("%Y-%m-%dT%H:%M:%S.%LZ")
          end
        end
      end
    end
  end
end
