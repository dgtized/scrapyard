# frozen_string_literal: true

require "spec_helper"
require "scrapyard/key"
require 'tempfile'

RSpec.describe Scrapyard::Key do
  let(:log) { double }

  context ".to_keys" do
    it "adds suffixes to array" do
      keys = Scrapyard::Key.to_keys(%w[a b], "prefix/", ".tgz", anything)
      expect(keys.map(&:to_s)).to eq %w[a.tgz b.tgz]
      expect(keys.map(&:local)).to eq %w[prefix/a.tgz prefix/b.tgz]
    end
  end

  context "checksum" do
    it "converts #(file) syntax to checksum" do
      expect(log).to receive(:debug).with(/Including sha1/)
      Tempfile.create("scrapyard") do |temp|
        temp.puts "foo"
        temp.close
        key = Scrapyard::Key.new("key-#(%s)" % [temp.path], "", log)
        expect(key.to_s).to eq "key-f1d2d2f924e986ac86fdf7b36c94bcdf32beec15"
      end
    end

    it "recovers from missing checksum file with empty string" do
      expect(log).to receive(:warn).with(/File missing-file does not exist/)
      key = Scrapyard::Key.new("key-#(missing-file)", "", log)
      expect(key.to_s).to eq "key-"
    end
  end

  context "local" do
    it "prefixes key with path" do
      key = Scrapyard::Key.new("key", Pathname.new("local"), log)
      expect(key.local).to eq Pathname.new("local/key")
    end
  end

  context "translation" do
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
        expect(log).to receive(:warn).with(/Translated key to/) if example != result
        expect(Scrapyard::Key.new(example, "", log).to_s).
          to eq(result)
      end
    end
  end
end
