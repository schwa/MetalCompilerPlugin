# MetalCompilerPlugin

A Swift Package Manager plugin to compile Metal files that can be debugged in Xcode Metal Debugger.

## Description

Swift Package Manager now[^1] seems to compile all Metal files within a target into a `default.metallib`. Alas, this file cannot be debugged in Xcode Metal Debugger.

> Unable to create shader debug session
>
> Source is unavailable
>
> Under the target's Build Settings, ensure the Metal Compiler Build Options produces debugging information and includes source code.
>
> If building with the 'metal' command line tool, include the options '-gline-tables-only' and '-frecord-sources'.

([Screenshot](Documentation/Screenshot%201.png)).

This plug-in provides an alternative way to compile Metal files into a `metallib` that can be debugged.

This project also shows how to create a ["_Pure-Metal target_"](#pure-metal-targets) that can be used to contain your Metal source code and header files.

[^1]: Prior to Swift Package Manager 5.3 it was impossible to process Metal files at all. Version 5.3 added the capability to process resources, including Metal files. Somewhere between versions 5.3 and 5.7 Swift Package Manager gained the ability to transparently compile all Metal files in a package.

## Usage

In your `Package.swift` file, add `MetalCompilerPlugin` as a dependency. And add the `MetalCompilerPlugin` to your target's `plugins` array.

For example:

```swift
    dependencies: [
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "main"),
    ],
    targets: [
        .target(name: "MyExampleShaders", plugins: [
            .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
        ]),
    ]
```

Note the title of the output metal library file will be `debug.metallib` and will live side-by-side with the `default.metallib` file. See [Limitations](#limitations) below.

## Limitations

The output metal library file will be `debug.metallib` and will live side-by-side with the `default.metallib` file. This is because of the `default.metallib` file is created by the Swift Package Manager and cannot be overridden.

You will not be able to use `MTLDevice.makeDefaultLibrary()` to load the `debug.metallib` file. Instead, you will need to use `MTLDevice.makeLibrary(url:)` to load the `debug.metallib` file. See the unit tests for an example.

## Pure-Metal Targets

A "Pure-Metal" target is a target that contains only Metal source code and header files. This is useful for projects that contain a lot of Metal code and want to keep it separate from the rest of the project.

This is also useful so that Metal and Swift can share types defined in common header files. For example, a Vertex or Uniforms struct defined in a header file can be used by both Metal and Swift code.

Direct sharing of Metal types with Swift prevents duplication of types and makes sure that your types have a consistent layout and packing across Metal and Swift. Simply defining the same type in both Metal and Swift manually is not enough and can lead to subtle memory alignment-related crashes or data corruption.

See the `ExampleShaders` target in the `Package.swift` file. The "Pure-Metal" target must not contain any Swift files. It should contain your Metal source code and header files (contained in an included folder). It should also contain a `Module.map` file that allows Swift to import the header files.

## Configuration

The plugin can be configured by placing a `metal-compiler-plugin.json` or `.metal-compiler-plugin.json` file in your target's directory. If no configuration file is found, the plugin will use default settings.

### Configuration Options

All configuration options are optional. Without any configuration file, the plugin will use the default settings (add debug flags, use xcrun, use a custom TMPDIR, do not enable logging).

```json
{
    "xcrun": true, // Use xcrun to find the metal compiler
    "metal": "/path/to/metal", // Direct path to the metal compiler executable (required if xcrun is false)
    "find-inputs": true, // Find all .metal files in the target directory
    "inputs": ["additional/file.metal"], // Additional input files to compile
    "output": "debug.metallib", // Name of the output metallib file
    "cache": "/path/to/cache", // Path to the modules cache directory - if not specified, defaults to the plugin work directory
    "flags": ["-gline-tables-only", "-frecord-sources"], // Compiler flags to pass to the metal compiler
    "plugin-logging": false, // If true, enables verbose logging from the plugin itself for debugging purposes
    "metal-enable-logging": false, // If true, enables metal compiler logging by adding the -fmetal-enable-logging flag
    "env": {
        "TMPDIR": "/private/tmp" // Additional environment variables to set when running the metal compiler
    }
}
```

#### Option Descriptions

- **`xcrun`** (boolean, default: `true`): Whether to use `xcrun` to find the metal compiler. When `true`, uses `/usr/bin/xcrun metal`. When `false`, you must specify the `metal` path.

- **`metal`** (string, required when `xcrun` is `false`): Direct path to the metal compiler executable.

- **`find-inputs`** (boolean, default: `true`): Whether to automatically scan the target directory for `.metal` files. When `true`, all `.metal` files in the target are included.

- **`inputs`** (array of strings, default: `[]`): Additional input files to compile, in addition to those found by scanning (if enabled).

- **`output`** (string, default: `"debug.metallib"`): Name of the output metallib file.

- **`cache`** (string, default: plugin work directory): Path to the modules cache directory.

- **`flags`** (array of strings, default: `["-gline-tables-only", "-frecord-sources"]`): Compiler flags to pass to the metal compiler. The default flags enable debugging in Xcode Metal Debugger.

- **`plugin-logging`** (boolean, default: `false`): Enable verbose logging from the plugin itself for debugging purposes.

- **`metal-enable-logging`** (boolean, default: `false`): Enable metal compiler logging by adding the `-fmetal-enable-logging` flag.

- **`env`** (object, default: `{}`): Additional environment variables to set when running the metal compiler.

### Example Configuration

For basic usage with debugging enabled:

```json
{
    "plugin-logging": true
}
```

For custom compiler flags:

```json
{
    "flags": ["-gline-tables-only", "-frecord-sources", "-O2"]
}
```

## License

BSD 3-clause. See [LICENSE.md](LICENSE.md).

## TODO

- [ ] File and link to feedback items for the limitations and issues above.
- [X] More configuration options.
- [ ] Searching for the metallib works in Xcode Unit Tests but fails under `swift test`. Why?
