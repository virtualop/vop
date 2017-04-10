require 'spec_helper'
require 'vop'
require 'vop/filter'
require 'pp'
require 'fileutils'

RSpec.describe Vop::Filter do

  include SpecHelper
  before(:example) do
    prepare
    @plugin_name = "funny_filters"
    @vop.new_plugin("path" => SpecHelper::TEST_SRC_PATH, "name" => @plugin_name)
  end

  it "filters requests" do
    name = "passthrough_filter"
    @vop.new_filter("plugin" => @plugin_name, "name" => name)
    request = ::Vop::Request.new(@vop, "identity", {}, {})
    response = request.execute()
    expect(response.result).to eq "localhost"
    expect(@vop.filters.keys).to include name
  end

SLARTIBART = <<EOT
run do
  raise ::Vop::DoNotContinue.new("slartibartfast", {})
end

EOT

  it "allows filters to change the result" do
    name = "blocking_filter"
    @vop.new_filter("plugin" => @plugin_name, "name" => name, "content" => SLARTIBART)
    expect(@vop.identity).to eq "slartibartfast"
  end

  it "can get a cache key from a command" do
    request = Vop::Request.new(@vop, "identity", {"foo" => "bar"})
    prepared = request.prepare
    expect(prepared).to_not be_nil
    ["foo", "bar", "identity", "v1"].each do |thing|
      expect(request.cache_key).to include thing
    end
  end

end
