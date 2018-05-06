begin
  require "active_support/inflector"
rescue Exception => e
  message = "active_support inflector cannot be loaded - pluralization results may deviate : #{e.message}"
  #puts message
end

module Vop

  module Pluralizer

    class ::String

      def carefully_pluralize
        begin
          self.pluralize(2)
        rescue
          "#{self}s"
        end
      end

    end

  end

end
