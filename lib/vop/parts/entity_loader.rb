require_relative "../syntax/entity_syntax"
require_relative "../objects/entity_definition"

module Vop

  class EntityLoader

    def initialize(plugin)
      @plugin = plugin
      @op = plugin.op

      @loaded = []

      @plugin.inject_helpers(self)

      #@command = @entity
      #extend CommandSyntax
      extend EntitySyntax
    end

    def prepare(name)
      @entity = EntityDefinition.new(@plugin, name)
      @command = @entity
      @loaded << @entity
      @entity
    end

    def read_sources(named_sources)
      # reads a hash of <name> => <source string>
      named_sources.each do |name, source|

        prepare(name)

        begin
          self.instance_eval(source[:code], source[:file_name])
        rescue SyntaxError => detail
          raise Errors::EntityLoadError.new("problem loading entity #{name} : #{detail.message}")
        end
      end

      @loaded
    end

  end

end
