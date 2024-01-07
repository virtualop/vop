require_relative "vop"

module Vop

  def self.gem_dependencies
    @cached_gem_dependencies ||= begin
      vop = ::Vop::Vop.new(no_init: true)
      vop.plugins.flat_map { |p| p.external_dependencies[:gem] }
    end
  end

end
