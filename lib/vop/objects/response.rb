module Vop

  class Response

    attr_reader :result, :context, :timestamp
    attr_accessor :status

    def initialize(result, context, timestamp = nil)
      @result = result
      @context = context
      @timestamp = timestamp || Time.now
      @status = "ok"
    end

  end

end
