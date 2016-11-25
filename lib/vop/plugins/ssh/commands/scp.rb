require 'net/scp'

param! 'machine'
param 'user'
param! 'local_path'
param! 'remote_path'

run do |machine, local_path, remote_path, params|
  user = params.has_key?('user') ? params['user'] : ENV['USER']
  Net::SCP.upload!(params['machine'], user, local_path, remote_path)
end
