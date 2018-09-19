# frozen_string_literal: true

require "spec_helper"
require "scrapyard/yard"

RSpec.describe Scrapyard::Yard do
  let(:s3) { Aws::S3::Client.new(stub_responses: true) }
  let(:logger) { double(info: nil, debug: nil)}
  let(:yard) { Scrapyard::AwsS3Yard.new("", logger, client: s3) }
  let(:now) { Time.now }

  before do
    FileUtils.mkdir_p 'scrapy'
    allow(yard).to receive(:to_path).and_return('scrapy')
  end
  after { FileUtils.rmtree 'scrapy' }

  context "search" do
    it "returns nil if bucket is empty" do
      s3.stub_responses(:list_objects, contents: [])
      expect(yard.search(["foo"])).to be_nil
    end

    it "finds key if match" do
      s3.stub_responses(
        :list_objects, contents: [{key: 'key.tgz', last_modified: now}]
      )

      expect(yard.search(["key"])).to eq(Pathname.new("scrapy/key.tgz"))
      expect(yard.search(%w[foo key])).to eq(Pathname.new("scrapy/key.tgz"))
    end

    it "finds most recent key when bucket contains multiple matches" do
      s3.stub_responses(
        :list_objects, contents: [
          {key: 'key-old.tgz', last_modified: now - 100},
          {key: 'key-new.tgz', last_modified: now}
        ]
      )

      expect(yard.search(["key"])).to eq(Pathname.new("scrapy/key-new.tgz"))
      expect(yard.search(["key-old", "key"])).to eq(Pathname.new("scrapy/key-old.tgz"))
    end

    it "finds first matching prefix when matching multiple" do
      s3.stub_responses(
        :list_objects, contents: [
          {key: 'key-1.tgz', last_modified: now},
          {key: 'key-2.tgz', last_modified: now}
        ]
      )

      expect(yard.search(["key"])).to eq(Pathname.new("scrapy/key-1.tgz"))
      expect(yard.search(%w[foo bar])).to be_nil
      expect(yard.search(["key-2", "key"])).to eq(Pathname.new("scrapy/key-2.tgz"))
    end
  end
end
