# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'light_store/version'

Gem::Specification.new do |spec|
  spec.name          = "light_store"
  spec.version       = LightStore::VERSION
  spec.authors       = ["Michael Kompanets"]
  spec.email         = ["mkompanets@gmail.com"]
  spec.description   = %q{A library for storing data about an object in spreadsheet-like format (array of hashes).}
  spec.summary       = %q{This library aims to provide an easy way to store report data about objects.  Data that is typically generated with complex queries and methods could be stored in a flat and accessible format.  This is meant to be a general purpose library, but it was created to improve performance of dynamic report generators.  This comes from an idea that each 'row' of report data could be identified by the object id and a secondary id relevant to the report.}
  spec.homepage      = "https://github.com/mkompanets/light_store"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "mock_redis"

  spec.add_dependency "redis"
end
