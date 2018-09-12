require 'spec_helper'

require 'tmpdir'

RSpec.describe "Commands" do
  before(:all) do
    system("rm -rf yard tmp")
    Dir.mkdir("tmp") unless File.exist?("tmp")
  end

  after(:all) do
    system("rm -rf yard tmp")
  end

  def scrap(args)
    expect(system("./scrapyard.rb #{args}")).to be_truthy
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

    scrap("search -k key -y yard -p #{dir}")

    assert_cache(dir, contents)
  end

  context "multiple caches" do
    let!(:cacheA) { make_cache("key-A", "a") }
    let!(:cacheB) { make_cache("key-B", "b") }

    it 'searches by mtime for multiple caches' do

      scrap("search -k key -y yard -p #{cacheB}")

      assert_cache(cacheB, "b")
    end

    it 'searches by key preference' do
      scrap("search -k key-A,key-B -y yard -p #{cacheA}")

      assert_cache(cacheA, "a")
    end

  end
end
