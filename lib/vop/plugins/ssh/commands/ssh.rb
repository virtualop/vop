require 'net/ssh'

param! 'machine'
param! 'command', :default_param => true
param 'user' #, :default => ENV['USER']
param 'key_file', :multi => true

run do |params|
  machine_name = params['machine']
  user = params.has_key?('user') ? params['user'] : ENV['USER']

  options = {}
  if params.has_key? 'key_file'
    options[:keys] = params['key_file']
  end
  Net::SSH.start(machine_name, user, options) do |ssh|
    ssh.exec! params['command']
  end
end
