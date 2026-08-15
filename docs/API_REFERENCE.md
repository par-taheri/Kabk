# Kabk - API & DSL Reference

This guide provides a comprehensive overview of the Kabk Domain Specific Language (DSL) used to define your resources, as well as the underlying architectural features like Validation, Relations, and the RestEngine.

For exact method signatures and class structures, please refer to the YARD documentation (`bundle exec yard server`).

---

## 1. Registering a Resource

Resources are registered into the global `Kabk::Registry` using the `Kabk.register` block. This maps your data model (e.g., via a Sequel Model) to the Kabk schema and assigns an appropriate adapter.

```ruby
require 'kabk'

class User < Sequel::Model; end

Kabk.register(name: "user", table: User) do
  # --- 1. General Configuration ---
  title fa: "مدیریت کاربران", en: "Users"
  plural_name "users"
  icon "Users"
  group "Administration"
  display_in_sidebar true
  order 1

  # --- 2. API & Data Configuration ---
  api_path "/api/admin/users"
  per_page_default 20
  default_sort "-created_at"
  
  # Search & Filter
  searchable_fields ["full_name", "email"]
  sortable_fields ["id", "created_at", "role"]
  filterable_fields ["role", "is_active", "created_at"]

  # Concurrency & Auditing (created_by and updated_by are auto-injected from context[:current_user_id])
  concurrency_field "updated_at"
  audit_fields ["created_by", "updated_by", "created_at", "updated_at"]

  # Permissions
  permissions can_view: true, can_insert: true, can_edit: true, can_delete: false

  # --- 3. Field Definitions ---
  field :id, type: :number, primary_key: true, hidden_in_form: true
  field :full_name, type: :string, form_type: :text, required: true
  field :email, type: :string, form_type: :email, required: true, validation: { unique: true, pattern: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }
end
```

### Resource Attributes Explained

| Attribute | Type | Description |
|-----------|------|-------------|
| **`title`** | Hash | A dictionary of localized names for the UI. e.g. `{ fa: "پست ها", en: "Posts" }` |
| **`plural_name`** | String | Used for API routing and JSON keys (e.g., `/api/admin/users`). |
| **`icon`** | String | The frontend icon identifier (e.g. Feather Icons or Material Icons name). |
| **`group`** | String | Groups resources together in the sidebar navigation. |
| **`display_in_sidebar`** | Boolean | Set to `false` to hide this resource from the main menu. |
| **`order`** | Integer | The explicit rendering order in the sidebar. |
| **`api_path`** | String | The fully qualified API path. |
| **`per_page_default`** | Integer | Default pagination size (default: 15). |
| **`default_sort`** | String | Default sorting column. Prefix with `-` for descending (e.g. `-created_at`). |
| **`searchable_fields`** | Array | Columns to search when a global `search=foo` query is sent. |
| **`sortable_fields`** | Array | Columns the frontend is allowed to sort by. |
| **`filterable_fields`** | Array | Columns the frontend is allowed to filter by. Supports exact match, comma-separated `IN`, and range queries (`gte`, `lte`, `gt`, `lt`, `eq`, `neq`). |
| **`concurrency_field`** | String | Used for Optimistic Concurrency Control (OCC). If the frontend sends an outdated timestamp, updates will be rejected with 409 Conflict. |
| **`audit_fields`** | Array | Configures standard audit fields (`created_by`, `updated_by`, `created_at`, `updated_at`). `created_by` and `updated_by` are automatically injected from `context[:current_user_id]`. |
| **`permissions`** | Hash | Boolean flags for CRUD ops (`can_view`, `can_insert`, `can_edit`, `can_delete`). |

---

## 2. Field Definitions

Fields map directly to your database columns and instruct the frontend on how to render inputs.

### Basic Syntax
```ruby
field :email, type: :string, form_type: :text, required: true, validation: { unique: true }
```

### Supported Data Types (`type`)
- `:string` (Text, Varchar)
- `:number` (Integer, Float)
- `:boolean` (True/False)
- `:date` (Date only)
- `:datetime` (Timestamp)
- `:file` (Images, Documents)
- `:relation` (Foreign Keys, Join Tables)

### Supported Form Types (`form_type`)
Dictates the HTML/React component used in the frontend:
- `:text`, `:textarea`, `:number`, `:email`, `:password`
- `:select`, `:multiselect`, `:switch`
- `:date`, `:datetime`
- `:image_single`, `:file_single`
- `:relation_select`
- `:wysiwyg` (Rich text editor)

### Field Modifiers

| Modifier | Type | Description |
|----------|------|-------------|
| **`primary_key`** | Boolean | Marks the ID field. |
| **`label`** | String | Human readable label. Defaults to titleized column name. |
| **`calendar`** | Symbol | Restricts date pickers (e.g. `:jalali` or `:gregorian`). |
| **`display_as`** | Symbol | Table rendering hints (`:badge`, `:thumbnail`, `:boolean_icon`). |
| **`hidden_in_table`** | Boolean | Hides the field from the main DataGrid. |
| **`hidden_in_form`** | Boolean | Hides the field from Create/Update forms. |
| **`col_width`** | Integer | Bootstrap grid width (1-12) for form layout. Defaults to 12. |
| **`accordion`** | Boolean | If true, places this field inside a collapsible section in the form. |
| **`depends_on`** | Hash | Conditional visibility. e.g. `{ field: "is_active", value: true }`. |

---

## 3. Relationships

Relations allow you to link resources together. The `RelationHydrator` automatically fetches the nested data when returning API responses.

### Many-To-One (Foreign Key)
Used when the current resource has an `author_id` that points to a `User`.

```ruby
field :author_id, 
      type: :relation, 
      form_type: :relation_select, 
      relation: { 
        resource: "user",             # The target registered resource
        cardinality: "many_to_one",   
        value_field: "id",            # PK on target
        label_field: "full_name"      # What to show in the dropdown
      }
```

### Many-To-Many (Join Tables / JSON arrays)
Used when a `NewsItem` has multiple `categories`.

```ruby
field :category_ids, 
      type: :relation, 
      form_type: :multiselect, 
      relation: { 
        resource: "category", 
        cardinality: "many_to_many", 
        value_field: "id", 
        label_field: "title" 
      }
```

---

## 4. Validation

Kabk performs strict server-side validation based on your DSL before executing database queries.

```ruby
field :username, type: :string, form_type: :text, validation: {
  min_length: 3,
  max_length: 20,
  unique: true,
  pattern: /\A[a-z0-9_]+\z/,
  custom_message: { fa: "نام کاربری نامعتبر است", en: "Username is invalid" }
}
```

**Supported Rules:**
* `unique: true` - Queries the database adapter to ensure no duplicate exists (excludes current ID on updates).
* `min_length: N` / `max_length: N` - For string length constraints.
* `min: N` / `max: N` - For numeric value constraints (`:number` fields).
* `pattern: /.../` or `pattern: "..."` - Regular expression matching for strings.
* `custom_message: "..."` or `custom_message: { fa: "...", en: "..." }` - Custom error message (String or localized Hash) returned when validation fails.

---

## 5. Working with the RestEngine

If you are not using `roda-kabk` and want to build your own HTTP layer (like Rails or Sinatra), you can interface directly with `Kabk::RestEngine`.

```ruby
engine = Kabk::RestEngine.new('news_item')

# 1. Fetching a List (Includes Range/IN Filtering, Search, Pagination & Hydration)
result = engine.list({ 
  "page" => 2, 
  "per_page" => 10, 
  "sort" => "-publish_date", 
  "search" => "hello",
  "filter" => { "author_id" => { "gte" => 10, "lte" => 50 } }
}, context: { current_user_id: 1 })
# => { success: true, data: [...], meta: { total: 50, page: 2, per_page: 10, last_page: 5 } }

# 2. Fetching a Single Record
result = engine.get(5, context: { current_user_id: 1 })
# => { success: true, data: { id: 5, title: "...", author_id: { id: 1, full_name: "Admin" } } }

# 3. Creating a Record (Audit fields such as created_by are automatically injected from context[:current_user_id])
result = engine.create({ "title" => "New Post", "author_id" => 1 }, context: { current_user_id: 1 })
# => { success: true, data: {...} }

# 4. Updating a Record (With OCC and Uniqueness check)
# If updated_at does not match the DB, it throws a 409 ApiError
result = engine.update(5, { "title" => "Edited", "updated_at" => "2026-08-01T10:00:00Z" }, context: { current_user_id: 1 })

# 5. Deleting a Record
result = engine.delete(5, context: { current_user_id: 1 })
```

---

## 6. Lifecycle Hooks

Kabk allows you to inject custom business logic immediately before or after any database action via block-based callbacks in your resource definition.

### Available Hooks

```ruby
Kabk.register(name: 'user', table: User) do
  # --- CREATE HOOKS ---
  before_create do |params, context|
    # Mutate params before hitting the adapter
    params['password_digest'] = BCrypt::Password.create(params.delete('password')) if params['password']
  end

  after_create do |record, context|
    # 'record' is the newly created hash from the database
    EmailService.send_welcome(record[:id])
  end

  # --- UPDATE HOOKS ---
  before_update do |id, params, context|
    # Receives the ID of the record being updated, and the incoming params
    params['last_modified_by'] = context[:current_user_id]
  end

  after_update do |record, context|
    # 'record' is the updated hash from the database
    AuditLog.create(action: 'update', resource_id: record[:id])
  end

  # --- DELETE HOOKS ---
  before_delete do |id, context|
    # Receives the ID. Can halt the process by raising an error.
    raise Kabk::ValidationError, 'Cannot delete super admins' if id == 1
  end

  after_delete do |id, context|
    # Receives the ID of the successfully deleted record
    AuditLog.create(action: 'delete', resource_id: id)
  end
end
```

### Flow and Error Handling
- **Mutations:** Any changes to params within `before_create` or `before_update` are validated and passed down to the DB adapter.
- **Halting Flow:** If a custom hook raises a `Kabk::ApiError` (e.g., `Kabk::ValidationError`), the RestEngine immediately halts, skips the database operation, and returns a standard error payload: `{ success: false, error: { message: ... } }`.
