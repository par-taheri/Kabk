# frozen_string_literal: true

module Kabk
  # Defines standardized API errors that map to protocol error codes
  class ApiError < StandardError
    attr_reader :code, :http_status, :fields

    def initialize(message, code: "SERVER_ERROR", http_status: 500, fields: {})
      super(message)
      @code = code
      @http_status = http_status
      @fields = fields
    end

    def to_h
      {
        success: false,
        error: {
          code: @code,
          message: message,
          fields: @fields
        }
      }
    end
  end

  # Error raised when request parameter validation fails (HTTP 422)
  class ValidationError < ApiError
    def initialize(message = "The submitted data is invalid", fields: {})
      super(message, code: "VALIDATION_ERROR", http_status: 422, fields: fields)
    end
  end

  # Error raised when the current password provided during password change is incorrect (HTTP 422)
  class InvalidOldPasswordError < ApiError
    def initialize(message = "The current password provided is incorrect", fields: {})
      super(message, code: "INVALID_OLD_PASSWORD", http_status: 422, fields: fields)
    end
  end

  # Error raised when authentication is missing or invalid (HTTP 401)
  class UnauthorizedError < ApiError
    def initialize(message = "Authentication required")
      super(message, code: "UNAUTHORIZED", http_status: 401)
    end
  end

  # Error raised when an authenticated user lacks permission for an action (HTTP 403)
  class ForbiddenError < ApiError
    def initialize(message = "Access denied")
      super(message, code: "FORBIDDEN", http_status: 403)
    end
  end

  # Error raised when a requested resource or record cannot be found (HTTP 404)
  class NotFoundError < ApiError
    def initialize(message = "Resource not found")
      super(message, code: "NOT_FOUND", http_status: 404)
    end
  end

  # Error raised when optimistic concurrency control detects a conflicting modification (HTTP 409)
  class ConcurrencyConflictError < ApiError
    def initialize(message = "Concurrent record modification detected")
      super(message, code: "CONCURRENCY_CONFLICT", http_status: 409)
    end
  end
end
