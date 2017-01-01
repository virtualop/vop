require 'vop'
require 'pp'
require 'fileutils'
require 'spec_helper'

RSpec.describe Vop do

  include SpecHelper
  before(:example) do
    prepare
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

  it "should allow to create and remove plugins" do
    old_plugin_list = @vop.list_plugins
    puts "old_plugin_list : #{old_plugin_list.inspect}"
    new_plugin = @vop.new_plugin('path' => SpecHelper::TEST_SRC_PATH, 'name' => 'rspec_test')
    expect(new_plugin).to_not be_nil
    new_plugin_list = @vop.list_plugins
    puts "new_plugin_list : #{new_plugin_list.join("\n")}"
    expect(new_plugin_list.length).to be > old_plugin_list.length

    old_plugin_list = new_plugin_list
    result = @vop.delete_plugin('name' => 'rspec_test')
    expect(result).to_not be_nil
    new_plugin_list = @vop.list_plugins
    expect(new_plugin_list.length).to be < old_plugin_list.length
  end

end
