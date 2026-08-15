# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kabk::QueryBuilder do
  let(:resource) { Kabk::Registry.instance.get("article") }

  before do
    MockArticle.create(title: "Article A", author_id: 10)
    MockArticle.create(title: "Article B", author_id: 20)
    MockArticle.create(title: "Article C", author_id: 30)
  end

  describe ".build" do
    it "filters with exact match string" do
      dataset = described_class.build(resource, { "filter" => { "title" => "Article A" } })
      expect(dataset.count).to eq(1)
      expect(dataset.first[:title]).to eq("Article A")
    end

    it "filters with comma-separated values for IN clause" do
      dataset = described_class.build(resource, { "filter" => { "title" => "Article A,Article B" } })
      expect(dataset.count).to eq(2)
      expect(dataset.map(:title)).to contain_exactly("Article A", "Article B")
    end

    it "filters with range conditions (gte, lte, gt, lt)" do
      dataset = described_class.build(resource, { "filter" => { "author_id" => { "gte" => 10, "lte" => 20 } } })
      expect(dataset.count).to eq(2)
      expect(dataset.map(:author_id)).to contain_exactly(10, 20)

      dataset_gt = described_class.build(resource, { "filter" => { "author_id" => { "gt" => 10, "lt" => 30 } } })
      expect(dataset_gt.count).to eq(1)
      expect(dataset_gt.first[:author_id]).to eq(20)
    end

    it "filters with eq and neq conditions" do
      dataset = described_class.build(resource, { "filter" => { "author_id" => { "neq" => 20 } } })
      expect(dataset.count).to eq(2)
      expect(dataset.map(:author_id)).to contain_exactly(10, 30)

      dataset_eq = described_class.build(resource, { "filter" => { "author_id" => { "eq" => 20 } } })
      expect(dataset_eq.count).to eq(1)
      expect(dataset_eq.first[:author_id]).to eq(20)
    end
  end
end
