# frozen_string_literal: true

require "rails/railtie"
require_relative "template"

module Grass
  module Sprockets
    class Railtie < ::Rails::Railtie
      initializer "grass.sprockets", after: "sprockets.environment", group: :all do |app|
        app.config.assets.configure do |env|
          env.register_transformer "text/scss", "text/css", Grass::Sprockets::ScssTemplate
          env.register_transformer "text/sass", "text/css", Grass::Sprockets::SassTemplate

          if env.respond_to?(:register_engine)
            args = [".scss", Grass::Sprockets::ScssTemplate]
            args << { silence_deprecation: true } if ::Sprockets::VERSION.start_with?("3", "4")
            env.register_engine(*args)

            args = [".sass", Grass::Sprockets::SassTemplate]
            args << { silence_deprecation: true } if ::Sprockets::VERSION.start_with?("3", "4")
            env.register_engine(*args)
          end
        end
      end
    end
  end
end
