# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'neohub/version'

Gem::Specification.new do |spec|
  spec.name          = "neohub"
  spec.version       = Neohub::VERSION
  spec.authors       = ["Vlatko Kosturjak"]
  spec.email         = ["vlatko.kosturjak@gmail.com"]

  spec.summary       = %q{Interface to Neohub in the cloud.}
  spec.description   = %q{Interface to Neohub in the cloud. Control your thermostat by ruby script.}
  spec.homepage      = "https://github.com/kost/neohub-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry", "> 0"
end
