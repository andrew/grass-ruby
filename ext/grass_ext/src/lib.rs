use magnus::{
    function, prelude::*, value::Lazy, Error, ExceptionClass, RHash, Ruby, Symbol, TryConvert,
    Value,
};
use std::path::PathBuf;

static COMPILE_RESULT: Lazy<Value> = Lazy::new(|ruby| ruby.eval("Grass::CompileResult").unwrap());

static COMPILE_ERROR: Lazy<ExceptionClass> =
    Lazy::new(|ruby| ruby.eval("Grass::CompileError").unwrap());

fn get_symbol_option(ruby: &Ruby, opts: RHash, key: &str) -> Option<String> {
    opts.get(ruby.sym_new(key))
        .and_then(|v| Symbol::from_value(v))
        .and_then(|s| s.name().ok())
        .map(|s| s.to_string())
}

fn get_bool_option(opts: RHash, key: &str) -> Option<bool> {
    let ruby = Ruby::get_with(opts);
    opts.get(ruby.sym_new(key)).and_then(|v| {
        if v.is_nil() {
            None
        } else {
            bool::try_convert(v).ok()
        }
    })
}

fn get_string_array_option(opts: RHash, key: &str) -> Vec<String> {
    let ruby = Ruby::get_with(opts);
    opts.get(ruby.sym_new(key))
        .and_then(|v| magnus::RArray::from_value(v))
        .map(|arr| arr.to_vec::<String>().unwrap_or_default())
        .unwrap_or_default()
}

fn build_options(ruby: &Ruby, opts: RHash) -> grass_compiler::Options<'static> {
    let mut options = grass_compiler::Options::default();

    if let Some(style_str) = get_symbol_option(ruby, opts, "style") {
        options = match style_str.as_str() {
            "compressed" => options.style(grass_compiler::OutputStyle::Compressed),
            _ => options.style(grass_compiler::OutputStyle::Expanded),
        };
    }

    if let Some(syntax_str) = get_symbol_option(ruby, opts, "syntax") {
        let input_syntax = match syntax_str.as_str() {
            "sass" => grass_compiler::InputSyntax::Sass,
            "css" => grass_compiler::InputSyntax::Css,
            _ => grass_compiler::InputSyntax::Scss,
        };
        options = options.input_syntax(input_syntax);
    }

    if let Some(charset) = get_bool_option(opts, "charset") {
        options = options.allows_charset(charset);
    }

    let load_paths = get_string_array_option(opts, "load_paths");
    for path in load_paths {
        options = options.load_path(PathBuf::from(path));
    }

    options
}

fn grass_error_to_ruby(ruby: &Ruby, err: Box<grass_compiler::Error>) -> Error {
    let message = err.to_string();
    Error::new(ruby.get_inner(&COMPILE_ERROR), message)
}

fn compile(ruby: &Ruby, path: String, opts: RHash) -> Result<Value, Error> {
    let options = build_options(ruby, opts);

    match grass_compiler::from_path(&path, &options) {
        Ok(css) => {
            let result_class = ruby.get_inner(&COMPILE_RESULT);
            result_class.funcall("new", (css,))
        }
        Err(err) => Err(grass_error_to_ruby(ruby, err)),
    }
}

fn compile_string(ruby: &Ruby, source: String, opts: RHash) -> Result<Value, Error> {
    let options = build_options(ruby, opts);

    match grass_compiler::from_string(source, &options) {
        Ok(css) => {
            let result_class = ruby.get_inner(&COMPILE_RESULT);
            result_class.funcall("new", (css,))
        }
        Err(err) => Err(grass_error_to_ruby(ruby, err)),
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    Lazy::force(&COMPILE_RESULT, ruby);
    Lazy::force(&COMPILE_ERROR, ruby);

    let module = ruby.define_module("Grass")?;
    let ext_module = module.define_module("GrassExt")?;

    ext_module.define_singleton_method("compile", function!(compile, 2))?;
    ext_module.define_singleton_method("compile_string", function!(compile_string, 2))?;

    Ok(())
}
