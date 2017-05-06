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

SLARTIBART = <<'EOT'
run do |command, request|
  puts "slartibartfast filtering #{command.short_name}"
  if command.short_name == "identity"
    raise ::Vop::DoNotContinue.new("slartibartfast", {})
  else
    (fresh_result, _context) = request.next_filter.execute_request(request)
    fresh_result
  end
end

EOT

  it "allows filters to change the result" do
    name = "blocking_filter"
    @vop.new_filter("plugin" => @plugin_name, "name" => name, "content" => SLARTIBART)
    expect(@vop.identity).to eq "slartibartfast"
  end

  it "can get a cache key from a command" do
    request = Vop::Request.new(@vop, "identity", {"foo" => "bar"})
    expect(request).to_not be_nil
    ["foo", "bar", "identity", "v1"].each do |thing|
      expect(request.cache_key).to include thing
    end
  end

end
