require_relative "../syntax/filter_syntax"
require_relative "../objects/filter"

module Vop

  class FilterLoader

    def initialize(plugin)
      @plugin = plugin
      @op = @plugin.op

      @filters = []

      @plugin.inject_helpers(self)
      extend FilterSyntax
    end

    def new_filter(name)
      @filter = Filter.new(@plugin, name)
      @filters << @filter
      @filter
    end

    def read_sources(named_sources)
      # reads a hash of <name> => <source string>
      named_sources.each do |name, source|
        new_filter(name)

        begin
          self.instance_eval(source[:code], source[:file_name])
        rescue => detail
          raise Errors::LoadError.new("problem loading filter #{name}", detail)
        end
      end

      @filters
    end

  end

end
