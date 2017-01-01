require "vop/filter"

module Vop

  class FilterLoader

    def initialize(plugin)
      @plugin = plugin

      @filters = {}
    end

    def new_filter(name)
      @filter = Filter.new(@plugin, name)
      @filters[@filter.name] = @filter
      @filter
    end

    def run(&block)
      @filter.block = block
    end

    # reads a hash of <name> => <source string>
    def read_sources(named)
      named.each do |name, source|

        new_filter(name)

        begin
          self.instance_eval(source[:code], source[:file_name])
        rescue => detail
          raise "problem loading filter #{name} : #{detail.message}\n#{detail.backtrace.join("\n")}"
        end
      end

      @filters
    end

  end

end
