require "spec_helper"

RSpec.describe Vop::Shell do

  it "executes commands like a REPL" do

    # PTY.spawn('') do |output, input|
    #   output.readpartial 1024 # read past the prompt
    # end

    Vop::Shell.run(nil, 'list_plugins')
  end

  it "passes on arguments" do
    Vop::Shell.run(nil, 'list_contributors machine')
  end

end
