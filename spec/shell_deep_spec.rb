require "spec_helper"

require "vop/shell/shell_input_testable"

RSpec.describe "shell in detail" do

  before(:example) do
    @vop = test_vop("shell_deep_spec")
    @input = Vop::TestableShellInput.new
    @shell = Vop::Shell.new(@vop, @input)
  end

  it "accepts pseudo input for tests" do
    @input.answers += %w|source source exit|

    begin
      @shell.do_it
    rescue => detail
      unless detail.message =~ /no more .+ answers/
        raise detail
      end
    end
    expect(@input.exit).to be true
  end

  it "does not like it when it does not have enough answers" do
    expect {
      @shell.do_it
    }.to raise_error(RuntimeError, /no more .+ answers/)
  end


end
