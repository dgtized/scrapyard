# frozen_string_literal: true

require "spec_helper"
require "scrapyard/key"

RSpec.describe Scrapyard::Key do
  context ".to_path" do
    it "adds suffixes to array with path" do
      yard = double(to_path: 'yard/')
      expect(Scrapyard::Key.to_path(yard, %w[a b], ".tgz", anything)).
        to eq %w[yard/a.tgz yard/b.tgz]
    end
  end

  context ".to_keys" do
    it "adds suffixes to array" do
      expect(Scrapyard::Key.to_keys(%w[a b], ".tgz", anything)).
        to eq %w[a.tgz b.tgz]
    end
  end

  let(:log) { double(debug: nil) }
  context "valid keys" do
    it "only allows legal characters" do
      {
        "a" => "a",
        "!" => "!",
        "[b]" => "!b!",
        "{c}" => "!c!",
        "(b)" => "!b!",
        "'a'" => "!a!",
        '"a"' => "!a!",
        ".-_" => ".-_",
        "a/b" => "a!b",
        "a/=b" => "a!!b"
      }.each do |example, result|
        expect(Scrapyard::Key.new(example, log).process!.to_s).
          to eq(result)
      end
    end
  end
end
