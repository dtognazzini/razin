# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'razin/version'

Gem::Specification.new do |spec|
  spec.name          = "razin"
  spec.version       = Razin::VERSION
  spec.authors       = ["Donnie Tognazzini"]
  spec.email         = ["donnie.tognazzini@appfolio.com"]
  spec.description   = "Tame dem sour grapes with Razin."
  spec.summary       = "Tame dem sour grapes with Razin."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
