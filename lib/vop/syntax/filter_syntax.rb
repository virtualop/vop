module Vop

  module FilterSyntax

    def run(&block)      
      @filter.block = block
    end

  end

end
