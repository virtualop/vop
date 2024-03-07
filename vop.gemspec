# encoding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "vop/version"
require "vop/search_path"

Gem::Specification.new do |spec|
  spec.name          = "vop"
  spec.version       = Vop::VERSION
  spec.authors       = ["Philipp T."]
  spec.email         = ["philipp@hitchhackers.net"]

  spec.summary       = %q{The vop is a scripting framework.}
  spec.description   = %q{Automation framework with a plugin/command architecture, entities, contributions, filters and asynchronous workers. Shell included, web interface in a separate project.}
  spec.homepage      = "http://virtualop.org"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  Vop.gem_dependencies.each do |dep|
    spec.add_dependency dep
  end unless ENV["VOP_IGNORE_PLUGINS"]

  spec.add_dependency "json", "~> 2.3"
  spec.add_dependency "terminal-table"
  spec.add_dependency "xml-simple"
  spec.add_dependency "byebug"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
end
