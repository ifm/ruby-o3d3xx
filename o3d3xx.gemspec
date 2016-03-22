# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'o3d3xx/version'

Gem::Specification.new do |spec|
  spec.name          = "o3d3xx"
  spec.version       = O3D3XX::VERSION
  spec.authors       = ["Christian Ege"]
  spec.email         = ["k4230r6@gmail.com"]
  spec.description   = "Ruby interface for ifm efector O3d3xx"
  spec.summary       = "Ruby interface for ifm efector O3d3xx"
  spec.homepage      = "https://github.com/graugans/ruby-o3d3xx"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.required_ruby_version = ">= 1.9.3"
end
