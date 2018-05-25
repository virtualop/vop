require "sidekiq"
require "json"

module Vop

  class AsyncExecutorWorker
    include Sidekiq::Worker

    def perform(request_json)
      begin
        op = ::Vop.boot
        request = ::Vop::Request::from_json(op, request_json)
        puts "performing #{request.command_name} #{request.param_values.pretty_inspect}"
        response = op.execute_request(request)
        puts "response : #{response.status}"
        puts response.result
      rescue => e
        puts "[ERROR] #{e.message}\n#{e.backtrace.join("\n")}"
      end
    end

  end

end
