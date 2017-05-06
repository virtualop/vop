require "net/ssh"

param! "machine"
param! "command", :default_param => true
param "user" #, :default => ENV["USER"]
param "key_file", :multi => true

run do |params|
  machine_name = params["machine"]

  ssh_opts = @op.ssh_options("machine" => machine_name)

  user = if params.has_key?("user")
    params["user"]
  else
    if ssh_opts.has_key?("user")
      ssh_opts["user"]
    else
      ENV["USER"]
    end
  end

  options = {}
  if params.has_key? "key_file"
    options[:keys] = params["key_file"]
  end
  host_or_ip = ssh_opts["host_or_ip"] || machine_name
  Net::SSH.start(host_or_ip, user, options) do |ssh|
    ssh.exec! params["command"]
  end
end
