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

    @shell.do_it

    expect(@input.exit).to be true
  end

  it "does not like it when it does not have enough answers" do
    expect {
      @shell.do_it
    }.to raise_error(RuntimeError, /no more .+ answers/)
  end

  it "displays a prompt" do
    @input.answers += %w|list_commands exit|

    @shell.do_it
    expect(@input.prompt).to eql ">> "
  end

  it "allows to change the prompt" do
    @input.answers += %w|change_prompt exit|
    @shell.do_it
    expect(@input.prompt).to eql "~_~"
  end

  it "handles interruptions" do
    # if a command is selected, the shell asks for the first mandatory param
    @input.answers = %w|source|
    @input.fail_if_out_of_answers = false
    @shell.do_it
    expect(@input.prompt).to eql "source.name ? "

    # if interrupted (simulated Ctrl+C), the shell should go back to command selection mode
    # @input.answers = %w|exit|
    @shell.handle_interrupt
    @shell.do_it

    expect(@input.prompt).to eql ">> "
  end
end
