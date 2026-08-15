# frozen_string_literal: true

require_relative "registry"

module Kabk
  # Renders the JSON Schema manifest for the protocol v1.6.0
  class SchemaRenderer
    # Initializes the schema renderer
    #
    # @param system_config [Hash, nil] Optional system config overrides (e.g., title, logo_url, endpoints)
    # @param validation_schema_url [String, nil] Custom URL for the validation schema
    def initialize(system_config: nil, validation_schema_url: nil)
      @system_config = system_config ? default_system_config.merge(system_config) : default_system_config
      @validation_schema_url = validation_schema_url || "/schemas/admin-protocol-1.6.0.json"
    end

    def render
      {
        "$schema_version": "1.6.0",
        system: @system_config,
        validation_schema_url: @validation_schema_url,
        resources: Registry.instance.all.map(&:to_h)
      }
    end

    private

    def default_system_config
      {
        title: { fa: "پنل مدیریت سیمرغ", en: "Simurgh Panel" },
        logo_url: "/simurgh-logo.svg",
        default_locale: "en",
        supported_locales: %w[en fa],
        direction: "ltr",
        endpoints: {
          upload: "/api/admin/uploads"
        },
        custom_fonts: [
          {
            name: "Lalezar",
            url: "https://fonts.gstatic.com/s/lalezar/v14/OpUp1a5dqj36gZ2zXh_WfQ.woff2",
            format: "woff2",
            label: { en: "Lalezar (Title)", fa: "لاله‌زار (عنوان)" }
          },
          {
            name: "Sahel",
            url: "https://cdn.jsdelivr.net/gh/rastikerdar/sahel-font@v3.4.0/dist/Sahel.woff2",
            format: "woff2",
            label: { en: "Sahel (Clean)", fa: "ساحل (خوانا)" }
          }
        ],
        custom_font_sizes: [
          {
            size: "15px",
            label: { en: "Medium Fine (15px)", fa: "متوسط ظریف (۱۵px)" }
          },
          {
            size: "20px",
            label: { en: "Sub-heading (20px)", fa: "زیرعنوان (۲۰px)" }
          },
          {
            size: "32px",
            label: { en: "Hero Display (32px)", fa: "تیتر برجسته (۳۲px)" }
          }
        ]
      }
    end
  end
end
