# -*- encoding: utf-8 -*-

require File.expand_path('../lib/geos/extensions/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "geos-extensions"
  s.version = Geos::Extensions::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["J Smith"]
  s.description = "Extensions for the GEOS library."
  s.summary = s.description
  s.email = "code@zoocasa.com"
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($\)
  s.executables = s.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "http://github.com/zoocasa/geos-extensions"
  s.require_paths = ["lib"]

  s.add_dependency("ffi-geos", ["~> 0.1"])
end

