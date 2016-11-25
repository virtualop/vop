require 'vop'
require 'pp'
require 'fileutils'

RSpec.describe Vop do

  test_src_path = '/tmp/vop_rspec_test'

  before(:example) do
    if File.exists? test_src_path
      FileUtils.rm_r test_src_path
    end
    Dir.mkdir test_src_path
    @vop = Vop::Vop.new
    @vop.add_search_path test_src_path
  end

  it "makes vop commands available as methods" do
    plugins = @vop.list_plugins
    expect(plugins.size).to be > 0
  end

  it "uses code from helpers and reads config" do
    expect(@vop.identity).to_not be_nil
  end

  it "should accept named params" do
    expect(@vop.source('name' => 'source')).to_not be_nil
  end

  it "should accept default params" do
    expect(@vop.source('source')).to_not be_nil
  end

  it "is possible to create and remove plugins" do
    old_plugin_list = @vop.list_plugins
    expect(@vop.new_plugin('path' => test_src_path, 'name' => 'rspec_test')).to_not be_nil
    new_plugin_list = @vop.list_plugins
    expect(new_plugin_list.length).to be > old_plugin_list.length

    old_plugin_list = new_plugin_list
    expect(@vop.delete_plugin('name' => 'rspec_test')).to_not be_nil
    new_plugin_list = @vop.list_plugins
    expect(new_plugin_list.length).to be < old_plugin_list.length
  end

end
