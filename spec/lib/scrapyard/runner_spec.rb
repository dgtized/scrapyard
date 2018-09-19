require "spec_helper"
require 'scrapyard'
require 'fileutils'

RSpec.describe Scrapyard::Runner do
  before(:all) do
    FileUtils.rmtree('scrapyard')
    FileUtils.mkdir_p('scrapyard')
  end
  let(:log) { spy('log') }
  let(:runner) { Scrapyard::Runner.new("scrapyard", log, {})}
  context "#store" do
    it "creates a tarball" do
      expect { runner.store(["key"], ['scrapyard.gemspec']) }.
        to change { File.exist?('scrapyard/key.tgz') }.to(true)
    end
  end

  context "#junk" do
    it "removes tarball from cache" do
      FileUtils.touch 'scrapyard/key.tgz'
      expect { runner.junk(["key"], []) }.
        to change { File.exist?('scrapyard/key.tgz') }.from(true)
    end
  end
end
