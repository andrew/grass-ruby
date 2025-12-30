# frozen_string_literal: true

# Compatibility shim for sassc-rails
# This allows gems like bootstrap-rubygem to detect a Sass engine
# while actually using grass-ruby under the hood

require "grass"
require "grass/sprockets"

module SassC
  module Rails
    VERSION = Grass::VERSION
  end
end
