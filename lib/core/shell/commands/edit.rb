param! "name", lookup: lambda { @op.commands.keys }

run do |params, name|
  has_vim = `which vim`
  editor = ENV["EDITOR"] || "vim" if has_vim
  raise "please set the EDITOR environment variable" unless editor

  command_file = @op.commands[name].source[:file_name]  
  system("#{editor} #{command_file}")

  @op.reset
end
