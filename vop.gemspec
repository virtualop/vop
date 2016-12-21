# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vop/version'

Gem::Specification.new do |spec|
  spec.name          = "vop"
  spec.version       = Vop::VERSION
  spec.authors       = ["Philipp T."]
  spec.email         = ["philipp@virtualop.org"]

  spec.summary       = %q{The virtualop is a tool for automating things.}
  spec.description   = %q{Automated things fail less frequently, that's why it's good to be able to easily write scripts.}
  spec.homepage      = "http://www.virtualop.org"
  
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "terminal-table"
  spec.add_dependency "net-ssh"
  spec.add_dependency "net-scp"
  spec.add_dependency "docopt"
  spec.add_dependency "activesupport"
  spec.add_dependency "pry"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
