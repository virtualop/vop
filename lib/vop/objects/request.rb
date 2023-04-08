require_relative "response"
require_relative "chain"
require_relative "../parts/executor"

module Vop

  class Request

    attr_reader :command_name, :param_values, :extra
    attr_accessor :shell
    attr_accessor :origin
    attr_accessor :dont_log

    def initialize(op, command_name, param_values = {}, extra = {}, origin = nil)
      @op = op
      @command_name = command_name
      raise "unknown command '#{command_name}'" if command.nil?
      @param_values = param_values
      @extra = extra
      @shell = nil

      @current_filter = nil
      @filter_chain = @op.filter_chain.clone
      # TODO not sure if this is really a hash out in the wild
      @origin = origin || {}

      @dont_log = false
    end

    def command
      @op.commands[@command_name]
    end

    def cache_key
      blacklist = %w|shell raw_params|

      ex = Executor.new(@op)
      prepared = ex.prepare_params(self)

      param_string = prepared.map { |k,v|
        next if blacklist.include? k
        [k.to_s,v].join("=")
      }.sort.compact.join(":")
      "vop/request:#{command.name}:" + param_string + ":v1"
    end

    def self.from_json(op, json)
      hash = JSON.parse(json)
      self.new(op, hash["command"], hash["params"], hash["extra"], hash["origin"])
    end

    def to_json
      {
          command: @command_name,
          params: @param_values,
          origin: @origin,
          extra: @extra
      }.to_json
    end

    def next_filter
       @chain.next()
    end

    def execute
      # build a chain out of all filters + the command itself
      filter_chain = @op.filter_chain.clone.map {
        |filter_name| @op.filters[filter_name.split(".").first]
      }
      filter_chain << Executor.new(@op)
      @chain = Chain.new(@op, filter_chain)
      @chain.execute(self)
    end

  end

end
