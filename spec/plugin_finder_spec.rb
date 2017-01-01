require "spec_helper"
require "vop/plugin_finder"

RSpec.describe "plugin finder" do

  include SpecHelper
  before(:example) do
    prepare

    vop_root = Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath
    @core_plugins = File.join(vop_root, "lib", "vop", "plugins")
  end

  it "finds core plugins" do
    finder = Vop::PluginFinder.new(@vop)
    expect(finder).to_not be_nil

    expected = %w|core meta ssh|.map { |x| File.join(@core_plugins, x) }

    result, _templates = finder.scan(@core_plugins)
    expect(result).to_not be_nil
    expect(result.sort).to eq(expected.sort)
  end

  it "finds plugins in multiple dirs" do
    finder = Vop::PluginFinder.new(@vop)

    @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "just_testing")
    result, _templates = finder.scan([@core_plugins, SpecHelper::TEST_SRC_PATH])
    expect(result).to_not be_nil
    expect(result.size).to be > 3
  end

  it "does not die when trying to read from a non-existing dir" do
    finder = Vop::PluginFinder.new(@vop)

    result, _templates = finder.scan(["/path/that/will/hopefully/not/exist/anywhere", @core_plugins])
    expect(result).to_not be_nil
    expect(result.size).to eq 3
  end

end
