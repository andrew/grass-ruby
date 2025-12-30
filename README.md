# grass-ruby

Ruby bindings for [grass](https://github.com/connorskees/grass), a Sass compiler written in Rust.

Compiles SCSS and Sass to CSS using native Rust code via [rb-sys](https://github.com/oxidize-rb/rb-sys) and [magnus](https://github.com/matsadler/magnus). Provides an API similar to sass-embedded for drop-in replacement in many cases.

## Installation

Add to your Gemfile:

```ruby
gem "grass-ruby"
```

Then run `bundle install`. The gem includes a native Rust extension that will be compiled during installation (requires Rust toolchain).

## Usage

```ruby
require "grass"

# Compile a file
result = Grass.compile("path/to/style.scss")
puts result.css

# Compile a string
result = Grass.compile_string("$color: red; .foo { color: $color; }")
puts result.css
# => .foo {
#      color: red;
#    }

# With options
result = Grass.compile_string(scss, style: :compressed)
result = Grass.compile_string(sass_code, syntax: :sass)
result = Grass.compile("style.scss", load_paths: ["./vendor/styles"])
```

## Options

- `style` - Output style: `:expanded` (default) or `:compressed`
- `syntax` - Input syntax: `:scss` (default), `:sass`, or `:css`
- `load_paths` - Array of paths to search for imports
- `charset` - Whether to include `@charset` declaration (default: true)

## Rails / Sprockets Integration

grass-ruby includes Sprockets integration for Rails applications. Add to your Gemfile:

```ruby
gem "grass-ruby"
```

The integration registers handlers for `.scss` and `.sass` files. It also provides a `sassc-rails` compatibility shim so gems that check for sassc-rails (like the bootstrap gem) will work.

The `asset-url()` helper is supported through CSS post-processing.

## Limitations

grass is a pure Rust implementation and does not support some features available in sass-embedded:

- Source maps
- Custom importers
- Custom functions
- Deprecation options (`fatal_deprecations`, `future_deprecations`, `silence_deprecations`)
- `quiet_deps`, `verbose`, `logger`

Attempting to use unsupported options raises `ArgumentError`.

## Requirements

- Ruby >= 3.1
- Rust toolchain (for building the native extension)

## License

MIT License. See LICENSE.txt for details.
