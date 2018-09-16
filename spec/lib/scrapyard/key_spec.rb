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
end
