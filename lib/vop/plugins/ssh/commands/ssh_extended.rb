require "net/ssh"

param! "machine"
param! "command", :default_param => true
param "user" #, :default => ENV["USER"]
param "key_file", :multi => true
param "on_data", :default => nil
param "on_stderr", :default => nil

run do |params, plugin|
  machine_name = params["machine"]

  ssh_opts = @op.ssh_options("machine" => machine_name)

  unless ssh_opts
    raise "no SSH options for machine #{machine_name}"
  end

  user = if params.has_key?("user")
    params["user"]
  else
    if ssh_opts.has_key?("user")
      ssh_opts["user"]
    else
      ENV["USER"]
    end
  end

  host_or_ip = ssh_opts["host_or_ip"] || machine_name
  port = ssh_opts["port"].to_i || 22

  options = {
    :port => port > 0 ? port : 22
  }
  if ssh_opts.has_key? "password"
    options[:password] = ssh_opts["password"]
  end
  if params.has_key? "key_file"
    options[:keys] = params["key_file"]
  end

  # TODO options should be part of the key
  key = "#{user}@#{host_or_ip}:#{port}"

  pool = plugin.state[:pool]
  connection = pool[key]
  if connection.nil?
    $logger.debug "new SSH connection as #{user} to #{host_or_ip} (#{options.pretty_inspect})"
    connection = Net::SSH.start(host_or_ip, user, options)
    pool[key] = connection
  end

  stdout = ""
  stderr = ""
  combined = ""
  result_code = nil
  connection.open_channel do |channel|
    # TODO we might need this for sudo commands - check
    if params.has_key?('request_pty') and params['request_pty'].to_s == "true"
      channel.request_pty do |ch, success|
        if success
        else
          raise Exception.new("could not obtain pty!")
        end
      end
    end

    channel.on_request('exit-status') do |c, data|
      result_code = data.read_long
      $logger.debug "read exit code : #{result_code}"
    end

    params["on_data"] ||= lambda do |c, data|
      stdout += data
      combined += data
      $logger.debug "got data on STDOUT #{data}"
    end
    channel.on_data do |c, data|
      params["on_data"].call(c, data)
    end

    params["on_stderr"] ||= lambda do |c, data|
      stderr += data
      combined += data
      $logger.debug "got data on STDERR #{data}"
    end
    channel.on_extended_data do |c, type, data|
      params["on_stderr"].call(c, data)
    end

    channel.on_close { $logger.debug "done" }

    command = params["command"]

    channel.exec(command) do |ch, success|
      if success
        $logger.debug "executed command successfully."
      else
        $logger.warn "could not execute command #{command}"
        raise RuntimeError.new("could not execute #{command}")
      end
    end
  end

  if params.has_key?('dont_loop') and params['dont_loop'] == "true"
    $logger.debug "not waiting for process to finish"
    {
      "combined" => combined,
      "stdout" => stdout,
      "stderr" => stderr,
      "connection" => connection
    }
  else
    $logger.debug "starting to loop"
    connection.loop

    {
      "combined" => combined,
      "stdout" => stdout,
      "stderr" => stderr,
      "result_code" => result_code
    }
  end
end
