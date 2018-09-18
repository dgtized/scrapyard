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
  end
end
