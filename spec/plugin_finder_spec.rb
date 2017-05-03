require "spec_helper"
require "vop/helpers/plugin_finder"

RSpec.describe "plugin finder" do

  include SpecHelper
  before(:example) do
    prepare

    vop_root = Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath
    @core_plugin_path = File.join(vop_root, "lib", "vop", "plugins")
    @finder =Vop::PluginFinder.new(@vop)
  end

  it "has a finder" do
    expect(@finder).to_not be_nil
  end

  it "finds core plugins" do
    expected = %w|core meta ssh|.map { |x| File.join(@core_plugin_path, x) }

    result, _templates = @finder.scan(@core_plugin_path)
    expect(result).to_not be_nil
    pp result
    expected.each do |one|
      expect(result.sort).to include(one)
    end
  end

  it "finds plugins in multiple dirs" do
    @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => "just_testing")
    result, _templates = @finder.scan([@core_plugin_path, SpecHelper::TEST_SRC_PATH])
    expect(result).to_not be_nil
    expect(result.size).to be > 5
  end

  it "does not die when trying to read from a non-existing dir" do
    result, _templates = @finder.scan(["/path/that/will/hopefully/not/exist/anywhere", @core_plugin_path])
    expect(result).to_not be_nil
    expect(result.size).to eq 5
  end

  it "can inspect plugins" do
    expect(@finder.inspect(File.join(@core_plugin_path, "core"))).to_not be_nil
  end

end
