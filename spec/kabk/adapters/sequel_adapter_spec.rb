# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kabk::Adapters::SequelAdapter do
  let(:resource) { Kabk::Registry.instance.get("article") }
  let(:adapter) { described_class.new(resource) }

  describe "#create" do
    it "creates a record in the database" do
      result = adapter.create({ title: "Test Article", content: "Lorem ipsum" })
      expect(result[:success]).to be true
      expect(result[:data][:title]).to eq "Test Article"
      expect(MockArticle.count).to eq 1
    end

    it "accepts context keyword argument" do
      result = adapter.create({ title: "With Context", content: "Body" }, context: { current_user_id: 123 })
      expect(result[:success]).to be true
      expect(result[:data][:title]).to eq "With Context"
    end
  end

  describe "#update" do
    let!(:article) { MockArticle.create(title: "Old Title", updated_at: Time.now - 3600) }

    it "updates the record" do
      result = adapter.update(article.id, { title: "New Title", updated_at: article.updated_at.iso8601 })
      expect(result[:success]).to be true
      expect(result[:data][:title]).to eq "New Title"
      expect(MockArticle.first.title).to eq "New Title"
    end

    it "accepts context keyword argument" do
      result = adapter.update(article.id, { title: "Updated With Context", updated_at: article.updated_at.iso8601 }, context: { current_user_id: 123 })
      expect(result[:success]).to be true
      expect(result[:data][:title]).to eq "Updated With Context"
    end

    it "raises ConcurrencyConflictError if OCC fails" do
      expect do
        adapter.update(article.id, { title: "New Title", updated_at: (Time.now - 7200).iso8601 })
      end.to raise_error(Kabk::ConcurrencyConflictError)
    end
  end

  describe "#list" do
    before do
      MockArticle.create(title: "First")
      MockArticle.create(title: "Second")
    end

    it "paginates results" do
      result = adapter.list({ "page" => 1, "per_page" => 1 })
      expect(result[:success]).to be true
      expect(result[:data].size).to eq 1
      expect(result[:meta][:total]).to eq 2
    end

    it "accepts context keyword argument" do
      result = adapter.list({ "page" => 1, "per_page" => 1 }, context: { current_user_id: 123 })
      expect(result[:success]).to be true
      expect(result[:data].size).to eq 1
    end
  end

  describe "#get" do
    let!(:article) { MockArticle.create(title: "Get Title") }

    it "gets a record by id" do
      result = adapter.get(article.id)
      expect(result[:success]).to be true
      expect(result[:data][:title]).to eq "Get Title"
    end

    it "accepts context keyword argument" do
      result = adapter.get(article.id, context: { current_user_id: 123 })
      expect(result[:success]).to be true
      expect(result[:data][:title]).to eq "Get Title"
    end
  end

  describe "#delete" do
    let!(:article) { MockArticle.create(title: "Delete Title") }

    it "deletes a record by id" do
      result = adapter.delete(article.id)
      expect(result[:success]).to be true
      expect(MockArticle.count).to eq 0
    end

    it "accepts context keyword argument" do
      result = adapter.delete(article.id, context: { current_user_id: 123 })
      expect(result[:success]).to be true
      expect(MockArticle.count).to eq 0
    end
  end

  describe "#exists?" do
    let!(:article) { MockArticle.create(title: "Unique Title") }

    it "returns true if a record with the field value exists" do
      expect(adapter.exists?(:title, "Unique Title")).to be true
    end

    it "returns false if no record with the field value exists" do
      expect(adapter.exists?(:title, "Non-existent Title")).to be false
    end

    it "excludes the specified id from the check" do
      expect(adapter.exists?(:title, "Unique Title", exclude_id: article.id)).to be false
    end

    it "returns true if another record with the same value exists when exclude_id is used" do
      MockArticle.create(title: "Unique Title")
      expect(adapter.exists?(:title, "Unique Title", exclude_id: article.id)).to be true
    end
  end
end
