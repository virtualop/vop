require "spec_helper"
require "vop/loaders/plugin_loader"

RSpec.describe Vop::PluginLoader do
  include SpecHelper
  before(:example) do
    prepare

    @loader = Vop::PluginLoader.new(@vop)
  end

  it "throws an error when a plugin is invalid" do
    expect {
      broken_path = File.join(SpecHelper::TEST_SRC_PATH, "broken")
      Dir.mkdir(broken_path)
      IO.write(File.join(broken_path, "broken.plugin"), "yo motherfucker, this {}")
      @loader.load([broken_path], [])
    }.to raise_error(NameError, /undefined.+motherfucker/)
  end
end
