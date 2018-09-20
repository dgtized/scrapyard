# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'
require 'tmpdir'
require 'English'

RSpec.describe "Commands" do
  before(:each) do
    FileUtils.rmtree(%w[yard tmp])
    FileUtils.mkdir_p("tmp")
  end

  after(:all) { FileUtils.rmtree(%w[yard tmp]) }

  def scrap(args, rval: 0)
    status, lines = IO.popen("ruby -Ilib bin/scrapyard #{args}") do |io|
      lines = io.readlines
      io.close
      [$CHILD_STATUS, lines]
    end
    expect(status.exitstatus).to eq rval
    lines.map(&:chomp)
  end

  def make_cache(name, contents)
    Dir.mktmpdir(nil, "tmp") do |dir|
      IO.write("#{dir}/foo", contents)
      scrap("store -k #{name} -y yard -p #{dir}")
      dir
    end
  end

  def assert_cache(name, contents)
    expect(File.exist?(name)).to be_truthy
    expect(IO.read(name + "/" + "foo")).to eq contents
  end

  it 'creates a cache' do
    contents = "alpaca"
    dir = make_cache("key", contents)

    expect(File.exist?(dir)).to be_falsey

    expect(File.exist?("yard/key.tgz")).to be_truthy

    expect(scrap("search -k key -y yard -p #{dir}")).to eq ["key.tgz"]

    assert_cache(dir, contents)
  end

  context "multiple caches" do
    let!(:cacheA) { make_cache("key-A", "a") }
    let!(:cacheB) { make_cache("key-B", "b") }

    it 'searches by mtime for multiple caches' do
      expect(scrap("search -k key -y yard -p #{cacheB}")).
        to eq ["key-B.tgz"]

      assert_cache(cacheB, "b")
    end

    it 'searches by key preference' do
      expect(scrap("search -k key-A,key-B -y yard -p #{cacheA}")).
        to eq ["key-A.tgz"]

      assert_cache(cacheA, "a")
    end
  end

  it "initializes paths" do
    path = Dir.mktmpdir(nil, "tmp") do |dir|
      IO.write("#{dir}/foo", "nothing")
      dir
    end

    expect(scrap("search -i -k missing -p #{path}", rval: 1)).to be_empty

    expect(Dir.exist?(path)).to be_truthy
    expect(File.exist?(path + "/foo")).to be_falsey
  end

  context "content sha" do
    let(:content) { "tmp/bar.file" }
    let(:key) { "content-ae2ad9454f3af7fcb18c83969f99b20a788eddd1.tgz" }
    before { IO.write(content, "quux") }
    after { File.delete content }

    it "incorporates sha in key" do
      expect(scrap("store -k 'content-#(tmp/bar.file)' -y yard -p tmp")).
        to eq([key])

      expect(File.exist?("yard/#{key}")).to be_truthy
    end
  end
end
