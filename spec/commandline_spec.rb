require 'spec_helper'
require 'pp'

RSpec.describe "CommandLine" do

  VOP_ROOT = Pathname.new(File.join(File.dirname(__FILE__), '..')).realpath

  include SpecHelper
  before(:example) do
    prepare
  end

  it "should be callable on the command line" do
    full_command = "#{VOP_ROOT}/exe/vop -e identity"
    output = `#{full_command}`
    $logger.info output
    last_line = output.split("\n").last.strip
    expect(last_line).to eql "localhost"
  end

  it "should result in a non-zero exit code when hitting an error" do
    full_command = "#{VOP_ROOT}/exe/vop -e this-command-should-not-exist"
    expect(system(full_command)).to be false
  end

end
