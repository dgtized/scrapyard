require "spec_helper"
require 'pathname'
require 'scrapyard/pack'

RSpec.describe Scrapyard::Pack do
  let(:log) { spy('log') }
  let(:pack) { Scrapyard::Pack.new(log) }
  context "save" do
    it "returns the cache path" do
      now = Time.now
      Tempfile.create('scrapyard') do |temp|
        path = temp.path + ".tgz"
        tarball = Pathname.new(
          pack.save(path, ["lib"])
        )
        expect(tarball).
          to have_attributes(to_s: path, mtime: be_within(0.1).of(now))
      end

      expect(log).to have_received(:info).with(/Executing/)
      expect(log).to have_received(:info).with(/Created/)
    end
  end

  context "restore" do
    it "restores from packfile" do
      Tempfile.create('scrapyard') do |temp|
        system("tar czf #{temp.path} lib/")
        expect(pack.restore(temp.path, ["lib"])).to eq 0
      end

      expect(log).to have_received(:info).with(/Executing/)
      expect(log).to have_received(:info).with(/Restored/)
    end
  end
end
