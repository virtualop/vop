require_relative "response"
require_relative "chain"
require_relative "../parts/executor"

module Vop

  class Request

    attr_reader :command_name, :param_values, :extra
    attr_accessor :shell

    def initialize(op, command_name, param_values = {}, extra = {})
      @op = op
      @command_name = command_name
      raise "unknown command '#{command_name}'" if command.nil?
      @param_values = param_values
      @extra = extra
      @shell = nil

      @current_filter = nil
      @filter_chain = @op.filter_chain.clone
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

    def next_filter
       @chain.next()
    end

    def execute
      result = nil
      context = nil

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
