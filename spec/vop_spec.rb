require 'spec_helper'
require 'vop'
require 'pp'
require 'fileutils'

RSpec.describe Vop do

  include SpecHelper
  before(:example) do
    prepare
  end

  it "has diagnostics" do
    diag = @vop.diagnostics
    expect(diag).to_not be_nil
  end

  it "is inspectable" do
    expect(@vop.inspect).to_not be_nil
  end

  it "has plugins" do
    plugins = @vop.list_plugins
    expect(plugins.size).to be > 0
  end

  it "only hands out existing commands" do
    expect { @vop.command("transmogrify") }.to raise_error
  end

  it "reads config" do
    expect(@vop.identity).to_not be_nil
  end

  it "accepts named params" do
    expect(@vop.source('name' => 'source')).to_not be_nil
  end

  it "accepts default params" do
    expect(@vop.source('source')).to_not be_nil
  end

  it "complains about missing mandatory params" do
    expect { @vop.source() }.to raise_error(RuntimeError)
  end

  it "shows mandatory params" do
    source_cmd = @vop.commands["source"]
    expect(source_cmd.mandatory_params.size).to be == 1
  end

  it "returns lookups" do
    source_cmd = @vop.commands["source"]
    expect(source_cmd.lookup("name", {}).size).to be > 0
  end

  it "allows to extend the search path" do
    new_path = File.join(SpecHelper::TEST_SRC_PATH, "foo")
    @vop.add_search_path(new_path)
    puts "+++ extended search path : #{@vop.show_search_path} +++"
    expect(@vop.show_search_path).to include(new_path)
  end

  it "should allow to create and remove plugins" do
    old_plugin_list = @vop.list_plugins
    new_plugin = @vop.new_plugin('path' => SpecHelper::TEST_SRC_PATH, 'name' => 'rspec_test')
    expect(new_plugin).to_not be_nil
    new_plugin_list = @vop.list_plugins
    expect(new_plugin_list.length).to be > old_plugin_list.length

    old_plugin_list = new_plugin_list
    result = @vop.delete_plugin('name' => 'rspec_test')
    expect(result).to_not be_nil
    new_plugin_list = @vop.list_plugins
    expect(new_plugin_list.length).to be < old_plugin_list.length
  end

  it "loads optional plugins if they are configured" do
    plugin_names = @vop.list_plugins.map { |x| x[:name] }
    expect(plugin_names).to include("core")
    expect(plugin_names).to_not include("foo")

    foo = @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "foo", "content" => "autoload false")
    transmogrify = @vop.new_command("plugin" => "foo", "name" => "transmogrify", "content" => "run { 42 }")
    plugins = @vop.list_plugins
    expect(plugins.map { |x| x[:name] }).to include("foo")
    foo_plugin = plugins.select { |x| x[:name] == "foo" }.first
    expect(foo_plugin[:loaded]).to be false

    @vop.plugins["foo"].config = {}
    @vop.plugins["foo"].write_config
    @vop.reset

    plugin_names = @vop.list_plugins.map { |x| x[:name] }
    expect(plugin_names).to include("foo")
  end

end
