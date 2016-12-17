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
  spec.description   = %q{Automated things fail less frequently. That's why it's good to be able to easily write scripts.}
  spec.homepage      = "http://www.virtualop.org"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "terminal-table"
  spec.add_dependency "net-ssh"
  spec.add_dependency "net-scp"
  spec.add_dependency "docopt"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
