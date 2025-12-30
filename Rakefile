# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

task default: :test

GEMSPEC = Gem::Specification.load("grass-ruby.gemspec")

Rake::ExtensionTask.new("grass_ext", GEMSPEC) do |ext|
  ext.lib_dir = "lib/grass"
  ext.cross_compile = true
  ext.cross_platform = %w[
    aarch64-linux-gnu
    aarch64-linux-musl
    arm-linux-gnu
    arm-linux-musl
    arm64-darwin
    x64-mingw-ucrt
    x64-mingw32
    x86-linux-gnu
    x86-linux-musl
    x86-mingw32
    x86_64-darwin
    x86_64-linux-gnu
    x86_64-linux-musl
  ]
end

task :dev do
  ENV["RB_SYS_CARGO_PROFILE"] = "dev"
end

Rake::TestTask.new(:test) do |t|
  t.deps = %i[dev compile]
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end
