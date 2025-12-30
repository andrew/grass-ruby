# frozen_string_literal: true

require_relative "lib/grass/version"

Gem::Specification.new do |spec|
  spec.name = "grass-ruby"
  spec.version = Grass::VERSION
  spec.authors = ["Andrew Nesbitt"]
  spec.email = ["andrewnez@gmail.com"]

  spec.summary = "A fast Sass compiler for Ruby, powered by grass (Rust)"
  spec.description = "Ruby bindings for the grass Sass compiler written in Rust. " \
                     "Provides a sass-embedded compatible API for compiling SCSS/Sass to CSS."
  spec.homepage = "https://github.com/andrew/grass-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.required_rubygems_version = ">= 3.3.26"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir[
    "lib/**/*.rb",
    "ext/**/*.{rs,rb,toml,lock}",
    "README.md",
    "LICENSE.txt",
    "Cargo.*"
  ]
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/grass_ext/extconf.rb"]

  spec.add_dependency "rb_sys", "~> 0.9"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rake-compiler", "~> 1.2"
  spec.add_development_dependency "test-unit", "~> 3.0"
end
