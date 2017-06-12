require "net/ssh"

# TODO params_as ssh_extended ?

param! "machine"
param! "command", :default_param => true
param "user" #, :default => ENV["USER"]
param "key_file", :multi => true

run do |params|
  result = @op.ssh_extended(params)

  $logger.info "ssh [#{params["machine"]}] #{params["command"]}, result : #{result["result_code"]}"
  unless result["result_code"].to_i == 0
    raise StandardError.new("SSH result code not zero")
  end

  result["combined"]
end
