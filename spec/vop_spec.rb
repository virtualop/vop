require "spec_helper"
require "vop"
require "pp"
require "fileutils"

RSpec.describe Vop do

  include SpecHelper
  before(:example) do
    prepare

    @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "vop_spec")
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
    expect { @vop.command("transmogrify") }.to raise_error(Vop::NoSuchCommand)
  end

  it "reads config" do
    expect(@vop.identity).to_not be_nil
  end

  it "allows to extend the search path" do
    new_path = File.join(SpecHelper::TEST_SRC_PATH, "foo")
    @vop.add_search_path(new_path)
    $logger.info "+++ extended search path : #{@vop.show_search_path} +++"
    expect(@vop.show_search_path).to include(new_path)
  end

  it "can create plugins and remove them again" do
    old_plugin_list = @vop.list_plugins
    new_plugin = @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "rspec_test")
    expect(new_plugin).to_not be_nil
    new_plugin_list = @vop.list_plugins
    expect(new_plugin_list.length).to be > old_plugin_list.length

    old_plugin_list = new_plugin_list
    result = @vop.delete_plugin("name" => "rspec_test")
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

  it "loads config for plugins and saves changes" do
    foo = @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "foo", "content" => "")
    plugins = @vop.list_plugins
    expect(plugins.map { |x| x[:name] }).to include("foo")

    @vop.plugins["foo"].config = {"zaphod" => "beeblebrox", "list" => ["foo", "bar", "baz"], "hash" => {"but" => "not", "yet" => "legal", "every" => "where"}}
    @vop.plugins["foo"].write_config
    @vop.reset

    expect(@vop.plugins["foo"].config["zaphod"]).to eq "beeblebrox"
  end

  it "handles circular dependencies between plugins" do
    plugins = @vop.plugins

    foo = ::Vop::Plugin.new(@vop, "foo", File.join(SpecHelper::TEST_SRC_PATH, "foo"))
    bar = ::Vop::Plugin.new(@vop, "bar", File.join(SpecHelper::TEST_SRC_PATH, "bar"))

    foo.dependencies << "bar"
    bar.dependencies << "foo"

    plugins["foo"] = foo
    plugins["bar"] = bar

    expect {
      ::Vop::DependencyResolver.order(@vop, plugins)
    }.to raise_error ::Vop::RunningInCircles, /bar -> foo/
  end

  it "complains about missing dependencies" do
    plugins = @vop.plugins

    plugins["foo"] = ::Vop::Plugin.new(@vop, "foo", File.join(SpecHelper::TEST_SRC_PATH, "foo"))
    plugins["foo"].dependencies << "peace on earth"

    expect {
      ::Vop::DependencyResolver.order(@vop, plugins)
    }.to raise_error ::Vop::MissingPlugin, /peace on earth/

  end

  # TODO it actually applies the plugin templates it finds
  # TODO it does not load plugins twice if they are on the search path twice

end
