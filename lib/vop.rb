require_relative "vop/version"
require_relative "vop/parts/shell"
require_relative "vop/vop"

module Vop

  def self.setup(options = {})
    Vop.new(options)
  end

end
