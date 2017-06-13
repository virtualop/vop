require "timeout"

param! "machine"
param "seconds", :default => 5

run do |params, seconds|
  result = nil
  begin
    Timeout::timeout(seconds) do
      @op.ssh("machine" => params["machine"], "command" => "id")
      result = true
    end
  rescue => detail
    if detail.message =~ /execution expired/
      result = false
    elsif detail.message =~ /No route to host/
      result = false
    else
      raise detail
    end
  end
  result
end
