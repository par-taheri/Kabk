# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kabk::RestEngine do
  let(:adapter) { instance_double("Kabk::Adapters::Base") }
  let(:hooks) { {} }
  let(:resource) { instance_double("Kabk::Resource", adapter: adapter, fields: [], concurrency_field: nil, hooks: hooks, audit_fields: nil) }

  before do
    allow(Kabk::Registry.instance).to receive(:get).with("article").and_return(resource)
  end

  let(:engine) { described_class.new("article") }

  describe "#create" do
    it "creates a record via adapter with valid params" do
      allow(Kabk::Validator).to receive(:validate_and_sanitize!).with(resource, { "title" => "Test Article" }).and_return({ title: "Test Article" })

      expect(adapter).to receive(:create).with({ title: "Test Article" }, context: {}).and_return({ success: true, data: { id: 1 } })

      result = engine.create({ "title" => "Test Article" })
      expect(result[:success]).to be true
    end

    it "returns error hash if validation fails and doesn't call adapter" do
      allow(Kabk::Validator).to receive(:validate_and_sanitize!).and_raise(Kabk::ValidationError.new(fields: { "title" => ["required"] }))

      expect(adapter).not_to receive(:create)

      result = engine.create({ "content" => "No title" })
      expect(result[:success]).to be false
      expect(result[:error][:code]).to eq("VALIDATION_ERROR")
    end

    it "executes before_create hook, mutates params, and executes after_create hook" do
      hooks[:before_create] = proc do |params, _context|
        params["title"] = params["title"].upcase
      end

      after_create_called = false
      hooks[:after_create] = proc do |record, _context|
        expect(record[:id]).to eq(1)
        after_create_called = true
      end

      # Validator receives the mutated params
      allow(Kabk::Validator).to receive(:validate_and_sanitize!).with(resource, { "title" => "TEST ARTICLE" }).and_return({ title: "TEST ARTICLE" })

      expect(adapter).to receive(:create).with({ title: "TEST ARTICLE" }, context: {}).and_return({ success: true, data: { id: 1, title: "TEST ARTICLE" } })

      result = engine.create({ "title" => "Test Article" })
      expect(result[:success]).to be true
      expect(after_create_called).to be true
    end

    it "auto-injects created_by when audit_fields includes created_by and current_user_id is in context" do
      allow(resource).to receive(:audit_fields).and_return(%w[created_by updated_by])
      allow(Kabk::Validator).to receive(:validate_and_sanitize!)
        .with(resource, { "title" => "Test Article", "created_by" => 99 })
        .and_return({ title: "Test Article", created_by: 99 })

      expect(adapter).to receive(:create).with({ title: "Test Article", created_by: 99 }, context: { current_user_id: 99 })
                                         .and_return({ success: true, data: { id: 1 } })

      result = engine.create({ "title" => "Test Article" }, context: { current_user_id: 99 })
      expect(result[:success]).to be true
    end

    it "validates uniqueness on create and raises ValidationError if duplicate exists" do
      unique_field = instance_double("Kabk::Field", name: "slug", validation: { unique: true })
      allow(resource).to receive(:fields).and_return([unique_field])
      allow(Kabk::Validator).to receive(:validate_and_sanitize!)
        .with(resource, { "slug" => "my-slug" })
        .and_return({ slug: "my-slug" })

      expect(adapter).to receive(:exists?).with(:slug, "my-slug", exclude_id: nil).and_return(true)
      expect(adapter).not_to receive(:create)

      result = engine.create({ "slug" => "my-slug" })
      expect(result[:success]).to be false
      expect(result[:error][:code]).to eq("VALIDATION_ERROR")
      expect(result[:error][:fields]).to eq({ "slug" => ["Already taken"] })
    end
  end

  describe "#update" do
    it "updates a record via adapter" do
      allow(Kabk::Validator).to receive(:validate_and_sanitize!).with(resource, { "title" => "New Title" }, is_update: true).and_return({ title: "New Title" })

      expect(adapter).to receive(:update).with(1, { title: "New Title" }, context: {}).and_return({ success: true, data: { id: 1 } })

      result = engine.update(1, { "title" => "New Title" })
      expect(result[:success]).to be true
    end

    it "executes before_update hook, mutates params, and executes after_update hook" do
      hooks[:before_update] = proc do |id, params, context|
        expect(id).to eq(1)
        params["modified_by"] = context[:user_id]
      end

      after_update_called = false
      hooks[:after_update] = proc do |record, _context|
        expect(record[:id]).to eq(1)
        after_update_called = true
      end

      allow(Kabk::Validator).to receive(:validate_and_sanitize!)
        .with(resource, { "title" => "New Title", "modified_by" => 42 }, is_update: true)
        .and_return({ title: "New Title", modified_by: 42 })

      expect(adapter).to receive(:update).with(1, { title: "New Title", modified_by: 42 }, context: { user_id: 42 }).and_return({ success: true, data: { id: 1 } })

      result = engine.update(1, { "title" => "New Title" }, context: { user_id: 42 })
      expect(result[:success]).to be true
      expect(after_update_called).to be true
    end

    it "auto-injects updated_by when audit_fields includes updated_by and current_user_id is in context" do
      allow(resource).to receive(:audit_fields).and_return(%i[created_by updated_by])
      allow(Kabk::Validator).to receive(:validate_and_sanitize!)
        .with(resource, { "title" => "New Title", "updated_by" => 77 }, is_update: true)
        .and_return({ title: "New Title", updated_by: 77 })

      expect(adapter).to receive(:update).with(1, { title: "New Title", updated_by: 77 }, context: { current_user_id: 77 })
                                         .and_return({ success: true, data: { id: 1 } })

      result = engine.update(1, { "title" => "New Title" }, context: { current_user_id: 77 })
      expect(result[:success]).to be true
    end

    it "validates uniqueness on update with exclude_id and rejects if another record has value" do
      unique_field = instance_double("Kabk::Field", name: "slug", validation: { unique: true, custom_message: "Slug taken" })
      allow(resource).to receive(:fields).and_return([unique_field])
      allow(Kabk::Validator).to receive(:validate_and_sanitize!)
        .with(resource, { "slug" => "taken-slug" }, is_update: true)
        .and_return({ slug: "taken-slug" })

      expect(adapter).to receive(:exists?).with(:slug, "taken-slug", exclude_id: 5).and_return(true)
      expect(adapter).not_to receive(:update)

      result = engine.update(5, { "slug" => "taken-slug" })
      expect(result[:success]).to be false
      expect(result[:error][:code]).to eq("VALIDATION_ERROR")
      expect(result[:error][:fields]).to eq({ "slug" => ["Slug taken"] })
    end
  end

  describe "#delete" do
    it "deletes a record via adapter" do
      expect(adapter).to receive(:delete).with(1, context: {}).and_return({ success: true })

      result = engine.delete(1)
      expect(result[:success]).to be true
    end

    it "executes after_delete hook" do
      after_delete_called = false
      hooks[:after_delete] = proc do |id, _context|
        expect(id).to eq(1)
        after_delete_called = true
      end

      expect(adapter).to receive(:delete).with(1, context: {}).and_return({ success: true })

      result = engine.delete(1)
      expect(result[:success]).to be true
      expect(after_delete_called).to be true
    end

    it "forwards context to adapter" do
      expect(adapter).to receive(:delete).with(1, context: { current_user_id: 123 }).and_return({ success: true })

      result = engine.delete(1, context: { current_user_id: 123 })
      expect(result[:success]).to be true
    end

    it "halts execution and returns error if before_delete raises ValidationError" do
      hooks[:before_delete] = proc do |_id, _context|
        raise Kabk::ValidationError.new("Cannot delete this record")
      end

      expect(adapter).not_to receive(:delete)

      result = engine.delete(1)
      expect(result[:success]).to be false
      expect(result[:error][:code]).to eq("VALIDATION_ERROR")
      expect(result[:error][:message]).to eq("Cannot delete this record")
    end
  end

  describe "#list" do
    it "lists records via adapter" do
      expect(adapter).to receive(:list).with({ "page" => 1 }, context: {}).and_return({ success: true })

      result = engine.list({ "page" => 1 })
      expect(result[:success]).to be true
    end

    it "forwards context to adapter" do
      expect(adapter).to receive(:list).with({ "page" => 1 }, context: { current_user_id: 123 }).and_return({ success: true })

      result = engine.list({ "page" => 1 }, context: { current_user_id: 123 })
      expect(result[:success]).to be true
    end
  end

  describe "#get" do
    it "gets a record via adapter" do
      expect(adapter).to receive(:get).with(1, context: {}).and_return({ success: true })

      result = engine.get(1)
      expect(result[:success]).to be true
    end

    it "forwards context to adapter" do
      expect(adapter).to receive(:get).with(1, context: { current_user_id: 123 }).and_return({ success: true })

      result = engine.get(1, context: { current_user_id: 123 })
      expect(result[:success]).to be true
    end
  end
end
