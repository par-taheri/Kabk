<h1 align="center">
  <img src="https://raw.githubusercontent.com/par-taheri/Kabk/main/Kabk_logo.svg" alt="Kabk Logo" width="200" />
</h1>

<p align="center">
  <a href="https://rubygems.org/gems/kabk"><img src="https://img.shields.io/gem/v/kabk.svg?color=blue" alt="Gem Version"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
</p>

> **Kabk carries the Ruby to Simorgh**

The framework-agnostic Ruby backend engine designed exclusively to power the Simurgh Panel.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kabk'
```

## Usage

This gem manages the metadata registry, schema manifest generation, server-side validation, pagination, query filtering, and concurrency control. Kabk is ORM-agnostic and relies on the Adapter pattern to interface with your database (e.g., via Sequel). It operates entirely on plain Ruby hashes and assumes your host application (like Roda or Rails) handles authentication and authorization.

### Registering a Resource

```ruby
require 'kabk'

# Assuming you have a Sequel Model
class NewsItem < Sequel::Model; end

# Kabk automatically detects Sequel models and uses the Kabk::Adapters::SequelAdapter

Kabk.register(name: 'news_item', table: NewsItem) do
  title fa: 'اخبار و اطلاعیه‌ها', en: 'News & Announcements'
  icon 'Newspaper'
  plural_name 'news'
  api_path '/api/admin/news'
  
  # Concurrency & Auditing (created_by and updated_by are auto-injected from context[:current_user_id])
  concurrency_field 'updated_at'
  audit_fields %w[created_by updated_by created_at updated_at]

  field :id, type: :number, form_type: :number, primary_key: true, hidden_in_form: true
  field :title, type: :string, form_type: :text, required: true, validation: { min_length: 5, unique: true }
  field :content, type: :string, form_type: :wysiwyg
  field :publish_date, type: :datetime, form_type: :datetime, calendar: :jalali
  
  # Lifecycle Hooks
  after_create do |record, context|
    # trigger background job
  end
end
```

### Generic REST Engine

The `Kabk::RestEngine` class orchestrates validation, unique checks, audit field injections, and delegates CRUD operations to the configured ORM adapter. It returns standardized raw hashes that your HTTP layer can easily convert to JSON.

```ruby
engine = Kabk::RestEngine.new('news_item')

# Pagination, Filtering (exact, IN, range), Sorting, and Hydration are automatic
result = engine.list({
  "page" => 1, 
  "per_page" => 15, 
  "sort" => "-created_at",
  "filter" => { "publish_date" => { "gte" => "2026-01-01" } }
}, context: { current_user_id: 1 })
# => { success: true, data: [...], meta: { ... } }

# Validation, Uniqueness, and OCC automatically applied
result = engine.update(1, { "title" => "New Title", "updated_at" => "2026-03-15T11:00:00Z" }, context: { current_user_id: 1 })
```

### System Configuration (Protocol v1.6.0)

Kabk generates a JSON schema manifest containing dynamic system configuration and UI settings. You can override these defaults by passing a custom hash to the `SchemaRenderer`. Ensure you inject your authentication endpoints here, as Kabk itself does not provide them.

```ruby
renderer = Kabk::SchemaRenderer.new(
  system_config: {
    title: { fa: "پنل مدیریت", en: "My Custom Admin" },
    subtitle: { fa: "سامانه مدیریت محتوا و داده‌ها", en: "Content & Data Management System" },
    logo_url: "/custom-logo.png",
    endpoints: {
      upload: "/api/files"
    },
    auth: {
      strategy: "session",
      show_demo_credentials: false,
      sso_redirect_url: nil,
      subtitle: { fa: "ورود به پنل ادمین سیمرغ", en: "Sign in to Simurgh Admin Panel" },
      login_url: "/auth/admin_login",
      me_url: "/auth/admin_me",
      logout_url: "/auth/admin_logout",
      refresh_url: "/auth/admin_refresh",
      login_fields: [
        {
          name: "email",
          label: { en: "Email", fa: "ایمیل" },
          placeholder: { en: "Enter your email...", fa: "ایمیل خود را وارد کنید..." },
          type: "text",
          required: true
        },
        {
          name: "password",
          label: { en: "Password", fa: "کلمه عبور" },
          placeholder: { en: "••••••••", fa: "••••••••" },
          type: "password",
          required: true
        }
      ]
    }
  }
)
schema = renderer.render
```

## Testing

```bash
bundle install
bundle exec rspec
```
