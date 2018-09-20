# frozen_string_literal: true

require "spec_helper"
require 'pathname'
require 'scrapyard/pack'

RSpec.describe Scrapyard::Pack do
  let(:log) { spy('log') }
  let(:pack) { Scrapyard::Pack.new(log) }
  let(:file) { "scrapyard.gemspec" }

  context "save" do
    it "returns the cache path" do
      now = Time.now
      Tempfile.create('scrapyard') do |temp|
        path = temp.path + ".tgz"
        tarball = Pathname.new(pack.save(path, [file]))
        expect(tarball).
          to have_attributes(to_s: path, mtime: be_within(0.1).of(now))
        File.unlink(path)
      end

      expect(log).to have_received(:info).with(/Executing/)
      expect(log).to have_received(:info).with(/Created/)
    end
  end

  context "restore" do
    it "restores from packfile" do
      Tempfile.create('scrapyard') do |temp|
        system("tar czf #{temp.path} #{file}")
        expect(pack.restore(temp.path, [file])).to be_truthy
      end

      expect(log).to have_received(:info).with(/Executing/)
      expect(log).to have_received(:info).with(/Restored:.*#{file}/m)
    end
  end
end
