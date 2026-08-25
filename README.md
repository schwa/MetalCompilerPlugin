# MetalCompilerPlugin

A Swift Package Manager plugin that compiles Metal source for debugging with Xcode's Metal debugger.

## Description

Swift Package Manager compiles the Metal files in a target into `default.metallib`. However, Xcode's Metal debugger cannot debug this library.

> Unable to create shader debug session
>
> Source is unavailable
>
> Under the target's Build Settings, ensure the Metal Compiler Build Options produces debugging information and includes source code.
>
> If building with the 'metal' command line tool, include the options '-gline-tables-only' and '-frecord-sources'.

([Screenshot](Documentation/Screenshot%201.png)).

The plugin compiles a Metal library that includes the data required by the debugger.

The project also shows how to create a [pure-Metal target](#pure-metal-targets) for Metal source and header files.

[^1]: Swift Package Manager 5.3 added support for resources, including Metal files. A later release added automatic Metal compilation.

## Usage

In `Package.swift`, add `MetalCompilerPlugin` as a package dependency. Add the plugin to the target and exclude its Metal source directory.

For example:

```swift
    dependencies: [
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "main"),
    ],
    targets: [
        .target(
            name: "MyExampleShaders",
            exclude: ["Shaders"],
            cSettings: [
                .define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))
            ],
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
    ]
```

The `METAL_COMPILER_PLUGIN_DEBUG` condition adds `-gline-tables-only` and `-frecord-sources` to debug builds. Release builds omit these flags and the shader source. Build-tool plugins cannot read the active build configuration directly. The conditional setting passes the configuration through the resolved target settings.

Put the Metal files in `Sources/MyExampleShaders/Shaders/`. The plugin scans excluded directories, but SwiftPM does not compile their contents.

## Tricks and Tips

### Produce One Metal Library

SwiftPM compiles recognized `.metal` files into `default.metallib`. The plugin also uses this name, so both build commands conflict.

Keep the Metal files in one directory and exclude that directory from the target:

```swift
.target(
    name: "MyExampleShaders",
    exclude: ["Shaders"],
    plugins: [
        .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
    ]
)
```

The plugin scans the target directory with `FileManager`, so it still finds files under `Shaders`. The output bundle contains one `default.metallib`.

Without a common directory, list each `.metal` file in `exclude`. SwiftPM does not support glob patterns in this setting.

### Include Headers from Another Package Target

Declare the package target as a dependency:

```swift
.target(
    name: "ExampleShaders",
    dependencies: ["DependencyShaders"],
    exclude: ["Shaders"],
    plugins: [
        .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
    ]
)
```

Enable dependency include paths in `Sources/ExampleShaders/metal-compiler-plugin.json`:

```json
{
    "include-dependencies": true
}
```

The Metal source can now include a header from `DependencyShaders`:

```metal
#include "DependencyShaders.h"
```

By default, the plugin adds each dependency target directory as an `-I` path. It also adds directories from transitive dependencies.

If each dependency stores headers in an `include` directory, add `"dependency-path-suffix": "include"` to the configuration.

## Pure-Metal Targets

A pure-Metal target keeps Metal code separate from the rest of the package. It contains Metal source, headers, and a small C-family implementation file.

Shared headers let Metal and Swift use the same types. This prevents duplicate declarations, layout differences, and data corruption.

See the `ExampleShaders` target in `Package.swift`. It uses `publicHeadersPath` and an empty `.m` file with the Metal source and headers.

## Configuration

Place `metal-compiler-plugin.json` or `.metal-compiler-plugin.json` in the target directory. If neither file exists, the plugin uses its defaults.

### Configuration Options

All options are optional. By default, the plugin uses `xcrun`, sets `TMPDIR`, and disables logging. Debug flags require `METAL_COMPILER_PLUGIN_DEBUG`.

```json
{
    "xcrun": true,
    "metal": "/path/to/metal",
    "find-inputs": true,
    "include-dependencies": false,
    "dependency-path-suffix": "include",
    "include-paths": ["Headers", "Metal/Include"],
    "inputs": ["additional/file.metal"],
    "output": "default.metallib",
    "cache": "/path/to/cache",
    "flags": ["-gline-tables-only", "-frecord-sources"],
    "plugin-logging": false,
    "verbose-logging": false,
    "metal-enable-logging": false,
    "logging-prefix": "[Metal]",
    "env": {
        "TMPDIR": "/private/tmp"
    }
}
```

#### Option Descriptions

- **`xcrun`** (boolean, default: `true`): Uses `/usr/bin/xcrun metal` to find the Metal compiler.

- **`metal`** (string): Sets the Metal compiler path. This option is required when `xcrun` is `false`.

- **`find-inputs`** (boolean, default: `true`): Scans the target directory for `.metal` files.

- **`include-dependencies`** (boolean, default: `false`): Adds dependency targets as include paths. This option includes product dependencies and transitive dependencies.

- **`dependency-path-suffix`** (string): Appends a suffix to each dependency include path. This option applies only when `include-dependencies` is `true`.

- **`include-paths`** (array of strings): Adds include paths relative to the target directory.

- **`inputs`** (array of strings, default: `[]`): Adds input files to those found by directory scanning.

- **`output`** (string, default: `"default.metallib"`): Sets the output file name.

- **`cache`** (string, default: plugin work directory): Sets the module cache directory.

- **`flags`** (array of strings): Replaces the configuration-dependent compiler flags. Without this option, marked debug builds include source information. Other builds add no flags.

- **`plugin-logging`** (boolean, default: `false`): Enables plugin logging.

- **`verbose-logging`** (boolean, default: `false`): Adds environment, command, input, and output details to plugin logs. This option requires `plugin-logging`.

- **`logging-prefix`** (string): Adds a prefix to each plugin log message.

- **`metal-enable-logging`** (boolean, default: `false`): Adds the `-fmetal-enable-logging` compiler flag.

- **`env`** (object, default: `{}`): Adds environment variables for the Metal compiler.

### Example Configuration

For basic plugin logging:

```json
{
    "plugin-logging": true
}
```

For verbose debugging with a custom prefix:

```json
{
    "plugin-logging": true,
    "verbose-logging": true,
    "logging-prefix": "[MyShaders]"
}
```

For custom compiler flags:

```json
{
    "flags": ["-gline-tables-only", "-frecord-sources", "-O2"]
}
```

For including headers from dependency targets:

```json
{
    "include-dependencies": true,
    "dependency-path-suffix": "include"
}
```

For adding custom include paths within your target:

```json
{
    "include-paths": ["Headers", "Shaders/Common", "Metal/Include"]
}
```

The plugin resolves each path from the target directory and passes it to the compiler with `-I`.

## License

BSD 3-clause. See [LICENSE.md](LICENSE.md).

