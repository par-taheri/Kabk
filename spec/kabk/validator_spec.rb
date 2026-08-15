# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kabk::Validator do
  let(:resource) do
    instance_double(
      "Kabk::Resource",
      concurrency_field: nil,
      fields: fields
    )
  end

  let(:fields) { [] }

  describe ".validate_and_sanitize!" do
    context "pattern (regex) validation" do
      let(:fields) do
        [
          Kabk::Field.new(
            name: :username,
            type: :string,
            form_type: :text,
            validation: { pattern: /\A[a-z_]+\z/ }
          )
        ]
      end

      it "accepts strings matching the regex pattern" do
        sanitized = described_class.validate_and_sanitize!(resource, { "username" => "john_doe" })
        expect(sanitized[:username]).to eq("john_doe")
      end

      it "rejects strings that do not match the regex pattern" do
        expect do
          described_class.validate_and_sanitize!(resource, { "username" => "John Doe 123" })
        end.to raise_error(Kabk::ValidationError) do |error|
          expect(error.fields["username"]).to eq(["Does not match the required format"])
        end
      end

      it "supports string regex patterns" do
        fields.first.validation = { pattern: "^[0-9]+$" }
        expect do
          described_class.validate_and_sanitize!(resource, { "username" => "abc" })
        end.to raise_error(Kabk::ValidationError)
      end
    end

    context "numeric min/max validation" do
      let(:fields) do
        [
          Kabk::Field.new(
            name: :age,
            type: :number,
            form_type: :number,
            validation: { min: 18, max: 65 }
          )
        ]
      end

      it "accepts numbers within range" do
        sanitized = described_class.validate_and_sanitize!(resource, { "age" => 25 })
        expect(sanitized[:age]).to eq(25)
      end

      it "rejects numbers below minimum" do
        expect do
          described_class.validate_and_sanitize!(resource, { "age" => 16 })
        end.to raise_error(Kabk::ValidationError) do |error|
          expect(error.fields["age"]).to eq(["Minimum value is 18"])
        end
      end

      it "rejects numbers above maximum" do
        expect do
          described_class.validate_and_sanitize!(resource, { "age" => 70 })
        end.to raise_error(Kabk::ValidationError) do |error|
          expect(error.fields["age"]).to eq(["Maximum value is 65"])
        end
      end

      it "accepts numeric strings and validates them properly" do
        expect do
          described_class.validate_and_sanitize!(resource, { "age" => "10" })
        end.to raise_error(Kabk::ValidationError) do |error|
          expect(error.fields["age"]).to eq(["Minimum value is 18"])
        end
      end
    end

    context "custom messages" do
      it "uses custom message as string when validation fails" do
        field = Kabk::Field.new(
          name: :code,
          type: :string,
          form_type: :text,
          validation: { pattern: /\A\d{4}\z/, custom_message: "Must be a 4-digit code" }
        )
        allow(resource).to receive(:fields).and_return([field])

        expect do
          described_class.validate_and_sanitize!(resource, { "code" => "invalid" })
        end.to raise_error(Kabk::ValidationError) do |error|
          expect(error.fields["code"]).to eq(["Must be a 4-digit code"])
        end
      end

      it "uses custom message as hash for localization when validation fails" do
        custom_msg = { fa: "حداقل طول باید ۳ کاراکتر باشد", en: "Minimum length is 3 characters" }
        field = Kabk::Field.new(
          name: :title,
          type: :string,
          form_type: :text,
          validation: { min_length: 3, custom_message: custom_msg }
        )
        allow(resource).to receive(:fields).and_return([field])

        expect do
          described_class.validate_and_sanitize!(resource, { "title" => "a" })
        end.to raise_error(Kabk::ValidationError) do |error|
          expect(error.fields["title"]).to eq([custom_msg])
        end
      end

      it "uses custom message for required field when specified" do
        custom_msg = { fa: "این فیلد اجباری است", en: "This field is mandatory" }
        field = Kabk::Field.new(
          name: :title,
          type: :string,
          form_type: :text,
          required: true,
          validation: { custom_message: custom_msg }
        )
        allow(resource).to receive(:fields).and_return([field])

        expect do
          described_class.validate_and_sanitize!(resource, {})
        end.to raise_error(Kabk::ValidationError) do |error|
          expect(error.fields["title"]).to eq([custom_msg])
        end
      end
    end

    context "required fields on create vs update" do
      let(:fields) do
        [
          Kabk::Field.new(name: :name, type: :string, form_type: :text, required: true)
        ]
      end

      it "fails on create if required field is missing" do
        expect do
          described_class.validate_and_sanitize!(resource, {})
        end.to raise_error(Kabk::ValidationError)
      end

      it "passes on update if required field is not provided" do
        sanitized = described_class.validate_and_sanitize!(resource, {}, is_update: true)
        expect(sanitized).to eq({})
      end

      it "fails on update if required field is provided as empty string" do
        expect do
          described_class.validate_and_sanitize!(resource, { "name" => "" }, is_update: true)
        end.to raise_error(Kabk::ValidationError)
      end
    end
  end
end
