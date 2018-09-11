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

  def make_cache(contents)
    Dir.mktmpdir(nil, "tmp") do |dir|
      IO.write("#{dir}/foo", contents)
      expect(system("./scrapyard.rb store -k key -y yard -p #{dir}")).to be_truthy
      dir
    end
  end

  it 'creates a cache' do
    contents = "alpaca"
    dir = make_cache(contents)

    expect(File.exist?(dir)).to be_falsey

    expect(File.exist?("yard/key.tgz")).to be_truthy

    expect(system("./scrapyard.rb search -k key -y yard -p #{dir}")).to be_truthy

    expect(File.exist?(dir)).to be_truthy

    expect(IO.read(dir + "/" + "foo")).to eq contents
  end
end
