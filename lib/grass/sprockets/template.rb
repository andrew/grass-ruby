# frozen_string_literal: true

require "sprockets"

module Grass
  module Sprockets
    class ScssTemplate
      VERSION = "1"

      def self.instance
        @instance ||= new
      end

      def self.call(input)
        instance.call(input)
      end

      def self.cache_key
        @cache_key ||= "#{name}:#{VERSION}:#{Grass::VERSION}".freeze
      end

      def call(input)
        context = input[:environment].context_class.new(input)
        filename = input[:filename]
        data = input[:data]
        load_paths = input[:environment].paths.dup

        syntax = filename.end_with?(".sass") ? :sass : :scss

        result = Grass.compile_string(
          data,
          syntax: syntax,
          load_paths: load_paths,
          style: style_for_environment
        )

        css = postprocess_asset_urls(result.css, context)

        context.metadata.merge(data: css)
      end

      def postprocess_asset_urls(css, context)
        css.gsub(/asset-url\(\s*['"]?([^'")]+)['"]?\s*\)/) do |_match|
          path = Regexp.last_match(1)
          # Strip leading /assets/ if present since asset_path will add it
          clean_path = path.sub(%r{^/assets/}, "").sub(%r{^/}, "")
          resolved = context.asset_path(clean_path)
          "url('#{resolved}')"
        end
      end

      def style_for_environment
        if defined?(Rails) && !Rails.env.development?
          :compressed
        else
          :expanded
        end
      end
    end

    class SassTemplate < ScssTemplate
    end
  end
end
