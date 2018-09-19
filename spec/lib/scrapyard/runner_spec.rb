# frozen_string_literal: true

require "spec_helper"
require 'scrapyard'
require 'fileutils'

RSpec.describe Scrapyard::Runner do
  before(:all) do
    FileUtils.rmtree('scrapyard')
    FileUtils.mkdir_p('scrapyard')
  end
  after(:all) { FileUtils.rmtree('scrapyard') }

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

  context "#crush" do
    let(:days) { 24 * 60 * 60 }
    it "removes stale tarballs from cache" do
      FileUtils.touch 'scrapyard/old.tgz', mtime: Time.now - 30 * days
      FileUtils.touch 'scrapyard/current.tgz', mtime: Time.now
      expect { runner.crush([], []) }.
        to change { File.exist?('scrapyard/old.tgz') }.from(true)

      expect(File.exist?('scrapyard/current.tgz')).to be_truthy
    end
  end
end
