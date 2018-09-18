# frozen_string_literal: true

require "spec_helper"
require "scrapyard/yard"

RSpec.describe Scrapyard::Yard do
  let(:s3) { Aws::S3::Client.new(stub_responses: true) }
  let(:logger) { double(info: nil, debug: nil)}
  let(:yard) { Scrapyard::AwsS3Yard.new("", logger, client: s3) }
  context "search" do
    it "returns nil if bucket is empty" do
      s3.stub_responses(:list_objects, contents: [])
      expect(yard.search(["foo"])).to be_nil
    end

    it "finds key if match" do
      s3.stub_responses(
        :list_objects, contents: [{key: 'key.tgz', last_modified: Time.now}]
      )

      expect(yard.search(["key"])).to eq(Pathname.new("/tmp/key.tgz"))
      expect(yard.search(["foo", "key"])).to eq(Pathname.new("/tmp/key.tgz"))
    end

    it "finds most recent key when bucket contains multiple matches" do
      s3.stub_responses(
        :list_objects, contents: [
          {key: 'key-old.tgz', last_modified: Time.now - 100},
          {key: 'key-new.tgz', last_modified: Time.now}
        ]
      )

      expect(yard.search(["key"])).to eq(Pathname.new("/tmp/key-new.tgz"))
      expect(yard.search(["key-old", "key"])).to eq(Pathname.new("/tmp/key-old.tgz"))
    end

    it "finds first matching prefix when matching multiple" do
      s3.stub_responses(
        :list_objects, contents: [
          {key: 'key-1.tgz', last_modified: Time.now},
          {key: 'key-2.tgz', last_modified: Time.now}
        ]
      )

      expect(yard.search(["key"])).to eq(Pathname.new("/tmp/key-1.tgz"))
      expect(yard.search(["key-2", "key"])).to eq(Pathname.new("/tmp/key-2.tgz"))
    end
  end
end
