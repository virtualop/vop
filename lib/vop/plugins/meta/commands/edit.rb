param! "name", :lookup => lambda { @op.list_commands.map { |x| x[:name] } }

run do |params, name|
  has_vim = `which vim`
  editor = ENV["EDITOR"] || "vim" if has_vim
  raise "please set the EDITOR environment variable" unless editor

  command_file = @op.command(name).source[:file_name]
  system("#{editor} #{command_file}")

  @op.reset
end