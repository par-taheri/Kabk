# frozen_string_literal: true

module Kabk
  # Handles applying page, sort, search, and filters to a Sequel dataset
  class QueryBuilder
    # @param resource [Kabk::Resource]
    # @param params [Hash] Request query parameters
    # @return [Sequel::Dataset] Paginated dataset
    def self.build(resource, params)
      dataset = resource.model_class.dataset

      dataset = apply_search(dataset, resource, params["search"])
      dataset = apply_filters(dataset, resource, params["filter"])
      dataset = apply_sort(dataset, resource, params["sort"] || resource.default_sort)

      apply_pagination(dataset, resource, params)
    end

    def self.apply_search(dataset, resource, search_term)
      return dataset if search_term.nil? || search_term.to_s.strip.empty?
      return dataset if resource.searchable_fields.nil? || resource.searchable_fields.empty?

      # Apply case-insensitive global search across all searchable fields.
      search_conditions = resource.searchable_fields.map do |field|
        Sequel.ilike(field.to_sym, "%#{search_term}%")
      end

      dataset.where(Sequel.|(*search_conditions))
    end

    def self.apply_filters(dataset, _resource, filters)
      return dataset unless filters.is_a?(Hash)

      filters.each do |field, value|
        dataset = if value.is_a?(Hash)
                    apply_range_filter(dataset, field, value)
                  else
                    apply_value_filter(dataset, field, value)
                  end
      end
      dataset
    end

    def self.apply_range_filter(dataset, field, hash_val)
      col = field.to_sym
      hash_val.each do |op, op_val|
        next if op_val.nil? || op_val.to_s.strip.empty?

        case op.to_s
        when "gte"
          dataset = dataset.where(Sequel[col] >= op_val)
        when "gt"
          dataset = dataset.where(Sequel[col] > op_val)
        when "lte"
          dataset = dataset.where(Sequel[col] <= op_val)
        when "lt"
          dataset = dataset.where(Sequel[col] < op_val)
        when "eq"
          dataset = dataset.where(col => op_val)
        when "neq"
          dataset = dataset.exclude(col => op_val)
        end
      end
      dataset
    end

    def self.apply_value_filter(dataset, field, value)
      # Parse comma-separated values to support SQL IN clauses.
      values = value.to_s.split(",")
      if values.size > 1
        dataset.where(field.to_sym => values)
      else
        dataset.where(field.to_sym => value)
      end
    end

    def self.apply_sort(dataset, resource, sort_term)
      return dataset if sort_term.nil? || sort_term.to_s.strip.empty?

      is_desc = sort_term.start_with?("-")
      field_name = is_desc ? sort_term[1..] : sort_term

      # Ensure sorting is only applied to permitted fields.
      if resource.sortable_fields&.include?(field_name)
        col = field_name.to_sym
        dataset = is_desc ? dataset.order(Sequel.desc(col)) : dataset.order(Sequel.asc(col))
      end
      dataset
    end

    def self.apply_pagination(dataset, resource, params)
      page = (params["page"] || 1).to_i
      per_page = (params["per_page"] || resource.per_page_default).to_i

      page = 1 if page < 1
      per_page = 15 if per_page < 1

      # Depends on Sequel's pagination extension (Sequel.extension :pagination).
      # Returns a paginated Sequel::Dataset.
      dataset.extension(:pagination).paginate(page, per_page)
    end
  end
end
