# frozen_string_literal: true

require_relative "grass/version"

module Grass
  class CompileError < StandardError; end

  class CompileResult
    attr_reader :css, :source_map

    def initialize(css)
      @css = css
      @source_map = nil
    end
  end
end

require_relative "grass/grass_ext"

module Grass
  class << self
    def compile(path, **options)
      validate_options!(options, allowed: %i[load_paths charset style])
      GrassExt.compile(path.to_s, normalize_options(options))
    end

    def compile_string(source, **options)
      validate_options!(options, allowed: %i[load_paths charset style syntax])
      GrassExt.compile_string(source.to_s, normalize_options(options))
    end

    def info
      "grass-ruby\t#{VERSION}\t(Rust)"
    end

    UNSUPPORTED_OPTIONS = %i[
      source_map source_map_include_sources
      functions importers importer
      alert_ascii alert_color
      fatal_deprecations future_deprecations silence_deprecations
      quiet_deps verbose logger url
    ].freeze

    def validate_options!(options, allowed:)
      unsupported = options.keys & UNSUPPORTED_OPTIONS
      if unsupported.any?
        raise ArgumentError, "Unsupported options: #{unsupported.join(', ')}. " \
          "grass does not support these sass-embedded features."
      end
    end

    def normalize_options(options)
      {
        style: normalize_style(options[:style]),
        load_paths: Array(options[:load_paths]),
        charset: options.fetch(:charset, true),
        syntax: normalize_syntax(options[:syntax])
      }
    end

    def normalize_style(style)
      case style
      when :compressed, "compressed" then :compressed
      else :expanded
      end
    end

    def normalize_syntax(syntax)
      case syntax
      when :sass, "sass" then :sass
      when :css, "css" then :css
      else :scss
      end
    end
  end
end

# Auto-require sprockets integration if sprockets and rails are loaded
if defined?(Sprockets) && defined?(Rails::Railtie)
  require_relative "grass/sprockets"
end
