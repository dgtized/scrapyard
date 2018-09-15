# frozen_string_literal: true

require "spec_helper"
require "scrapyard/key"

RSpec.describe Scrapyard::Key do
  it "adds suffixes to array" do
    yard = double(to_path: 'yard/')
    expect(Scrapyard::Key.to_path(yard, %w[a b], ".tgz", anything)).
      to eq %w[yard/a.tgz yard/b.tgz]
  end
end
