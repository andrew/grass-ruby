# frozen_string_literal: true

require "test_helper"
require "tempfile"

class GrassTest < Test::Unit::TestCase
  def test_compile_string_basic
    result = Grass.compile_string("a { b { color: red; } }")

    assert_instance_of Grass::CompileResult, result
    assert_includes result.css, "a b {"
    assert_includes result.css, "color: red"
    assert_nil result.source_map
  end

  def test_compile_string_compressed
    result = Grass.compile_string("a { color: red; }", style: :compressed)

    assert_equal "a{color:red}", result.css.strip
  end

  def test_compile_string_expanded
    result = Grass.compile_string("a { color: red; }", style: :expanded)

    assert_includes result.css, "a {\n"
    assert_includes result.css, "  color: red;"
  end

  def test_compile_string_sass_syntax
    sass_source = <<~SASS
      a
        color: red
    SASS

    result = Grass.compile_string(sass_source, syntax: :sass)

    assert_includes result.css, "color: red"
  end

  def test_compile_string_with_variables
    scss = <<~SCSS
      $color: blue;
      a { color: $color; }
    SCSS

    result = Grass.compile_string(scss)

    assert_includes result.css, "color: blue"
  end

  def test_compile_string_with_nesting
    scss = <<~SCSS
      nav {
        ul {
          li {
            display: inline-block;
          }
        }
      }
    SCSS

    result = Grass.compile_string(scss)

    assert_includes result.css, "nav ul li"
  end

  def test_compile_string_with_mixins
    scss = <<~SCSS
      @mixin flex-center {
        display: flex;
        justify-content: center;
      }
      .container {
        @include flex-center;
      }
    SCSS

    result = Grass.compile_string(scss)

    assert_includes result.css, "display: flex"
    assert_includes result.css, "justify-content: center"
  end

  def test_compile_file
    Tempfile.create(["test", ".scss"]) do |f|
      f.write("a { color: red; }")
      f.flush

      result = Grass.compile(f.path)

      assert_instance_of Grass::CompileResult, result
      assert_includes result.css, "color: red"
    end
  end

  def test_compile_file_with_import
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "_variables.scss"), "$primary: blue;")
      File.write(File.join(dir, "main.scss"), <<~SCSS)
        @import "variables";
        a { color: $primary; }
      SCSS

      result = Grass.compile(File.join(dir, "main.scss"))

      assert_includes result.css, "color: blue"
    end
  end

  def test_compile_with_load_paths
    Dir.mktmpdir do |lib_dir|
      Dir.mktmpdir do |src_dir|
        File.write(File.join(lib_dir, "_shared.scss"), "$shared-color: green;")
        File.write(File.join(src_dir, "app.scss"), <<~SCSS)
          @import "shared";
          body { color: $shared-color; }
        SCSS

        result = Grass.compile(
          File.join(src_dir, "app.scss"),
          load_paths: [lib_dir]
        )

        assert_includes result.css, "color: green"
      end
    end
  end

  def test_compile_error
    assert_raise(Grass::CompileError) do
      Grass.compile_string("a { color: $undefined; }")
    end
  end

  def test_compile_error_invalid_syntax
    assert_raise(Grass::CompileError) do
      Grass.compile_string("a { color: }")
    end
  end

  def test_compile_file_not_found
    assert_raise(Grass::CompileError) do
      Grass.compile("/nonexistent/file.scss")
    end
  end

  def test_unsupported_source_map_option
    assert_raise(ArgumentError) do
      Grass.compile_string("a { color: red; }", source_map: true)
    end
  end

  def test_unsupported_functions_option
    assert_raise(ArgumentError) do
      Grass.compile_string("a { color: red; }", functions: {})
    end
  end

  def test_unsupported_importers_option
    assert_raise(ArgumentError) do
      Grass.compile_string("a { color: red; }", importers: [])
    end
  end

  def test_info
    info = Grass.info

    assert_includes info, "grass-ruby"
    assert_includes info, Grass::VERSION
  end
end

class BootstrapTest < Test::Unit::TestCase
  BOOTSTRAP_VERSION = "5.3.2"
  BOOTSTRAP_DIR = File.expand_path("../fixtures/bootstrap-#{BOOTSTRAP_VERSION}", __FILE__)

  def self.startup
    return if File.directory?(BOOTSTRAP_DIR)

    fixtures_dir = File.expand_path("../fixtures", __FILE__)
    FileUtils.mkdir_p(fixtures_dir)

    tarball = File.join(fixtures_dir, "bootstrap.tar.gz")
    url = "https://github.com/twbs/bootstrap/archive/refs/tags/v#{BOOTSTRAP_VERSION}.tar.gz"

    system("curl", "-sL", url, "-o", tarball, exception: true)
    system("tar", "-xzf", tarball, "-C", fixtures_dir, exception: true)
    File.delete(tarball)
  end

  def test_compile_bootstrap
    skip "Bootstrap not downloaded" unless File.directory?(BOOTSTRAP_DIR)

    scss_path = File.join(BOOTSTRAP_DIR, "scss", "bootstrap.scss")
    result = Grass.compile(scss_path)

    assert_instance_of Grass::CompileResult, result
    assert result.css.bytesize > 200_000, "Expected large CSS output"
    assert_includes result.css, "Bootstrap"
    assert_includes result.css, ":root"
  end

  def test_compile_bootstrap_compressed
    skip "Bootstrap not downloaded" unless File.directory?(BOOTSTRAP_DIR)

    scss_path = File.join(BOOTSTRAP_DIR, "scss", "bootstrap.scss")
    result = Grass.compile(scss_path, style: :compressed)

    assert_instance_of Grass::CompileResult, result
    assert result.css.bytesize > 150_000, "Expected large CSS output"
    assert result.css.bytesize < 250_000, "Compressed should be smaller than expanded"
    # Compressed output has no newlines in rules (comments may still have them)
    assert_includes result.css, ".container{" # No space before brace
  end

  def test_compile_bootstrap_grid_only
    skip "Bootstrap not downloaded" unless File.directory?(BOOTSTRAP_DIR)

    scss_path = File.join(BOOTSTRAP_DIR, "scss", "bootstrap-grid.scss")
    result = Grass.compile(scss_path)

    assert_instance_of Grass::CompileResult, result
    assert_includes result.css, ".container"
    assert_includes result.css, ".row"
    assert_includes result.css, ".col"
  end

  def test_compile_bootstrap_utilities_only
    skip "Bootstrap not downloaded" unless File.directory?(BOOTSTRAP_DIR)

    scss_path = File.join(BOOTSTRAP_DIR, "scss", "bootstrap-utilities.scss")
    result = Grass.compile(scss_path)

    assert_instance_of Grass::CompileResult, result
    assert_includes result.css, ".d-flex"
    assert_includes result.css, ".text-center"
  end

  def test_compile_bootstrap_reboot_only
    skip "Bootstrap not downloaded" unless File.directory?(BOOTSTRAP_DIR)

    scss_path = File.join(BOOTSTRAP_DIR, "scss", "bootstrap-reboot.scss")
    result = Grass.compile(scss_path)

    assert_instance_of Grass::CompileResult, result
    assert_includes result.css, "body"
    assert_includes result.css, "margin"
  end
end
