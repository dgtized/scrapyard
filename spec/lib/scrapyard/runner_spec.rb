require "spec_helper"
require 'scrapyard'
require 'fileutils'

RSpec.describe Scrapyard::Runner do
  before(:all) { FileUtils.rmtree('scrapyard') }
  let(:log) { spy('log') }
  let(:runner) { Scrapyard::Runner.new("scrapyard", log, {})}
  context "#store" do
    it "creates a tarball" do
      expect { runner.store(["key"], ['scrapyard.gemspec']) }.
        to change { File.exist?('scrapyard/key.tgz') }.to(true)
    end
  end
end
