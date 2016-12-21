#!/usr/bin/env ruby

require 'pathname'

$: << File.join(Pathname.new(File.join(File.dirname(__FILE__), '..')).realpath, 'lib')

require 'vop/shell'
require 'docopt'
require 'pp'

begin
  shell = Vop::Shell::setup()
  if shell.options["--execute"]
    last_response = shell.execute(shell.options["--execute"])
  else
    last_response = shell.run_cli
  end

  # TODO exit_status = last_response && last_response.status == Vop.Status::OK ? 0 : 1
  exit 0
rescue => detail
  if detail.is_a? Docopt::Exit
    puts detail.message
  else
    $stderr.puts "error : #{detail.message}\n#{detail.backtrace[0..9].join("\n")}"
    exit 42
  end
end
