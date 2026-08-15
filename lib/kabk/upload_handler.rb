# frozen_string_literal: true

module Kabk
  # Handles generic file uploads and formats them according to Protocol v1.6.0
  class UploadHandler
    # @param url [String] Public URL of the uploaded file
    # @param file_name [String] Original file name
    # @param size [Integer] File size in bytes
    # @param mime_type [String] File mime type
    # @return [Hash] Formatted upload response
    def self.format_response(url:, file_name:, size:, mime_type: nil)
      {
        success: true,
        message: "File uploaded successfully",
        data: {
          url: url,
          file_name: file_name,
          size: size,
          mime_type: mime_type || "application/octet-stream"
        }
      }
    end
  end
end
