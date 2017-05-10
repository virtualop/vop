require 'spec_helper'
require 'pp'

RSpec.describe "command_line_shell" do

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

  it "prints version info when asked" do
    full_command = "#{VOP_ROOT}/exe/vop -V"
    version_info = `#{full_command}`.lines.last
    expect(version_info).to_not be nil
    $logger.info "v #{version_info}"
    expect(version_info.strip).to match /^[\.\d]+$/
  end

end
