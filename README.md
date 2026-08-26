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

`METAL_COMPILER_PLUGIN_DEBUG` selects the `debug` section. Without the condition, the plugin selects `release`. SwiftPM does not expose the active build configuration directly, so the package condition supplies this selection.

The selected section's `flags` override top-level `flags`. Without either value, Debug adds source information and Release adds no flags.

> **IMPORTANT:** Existing top-level `flags` continue to work in every build configuration that does not override them.

Put the Metal files in `Sources/MyExampleShaders/Shaders/`. The plugin scans excluded directories, but SwiftPM does not compile their contents.

## Configuration

Place `metal-compiler-plugin.json` or `.metal-compiler-plugin.json` in the target directory. If neither file exists, the plugin uses its defaults.

### Configuration Options

Configuration files use JSON5. They support `//` line comments, `/* */` block comments, and trailing commas. All options are optional. Remove options that you do not need.

The `debug` and `release` sections accept `flags`. All other options remain at the top level.

```jsonc
{
    // Find Metal through /usr/bin/xcrun. Default: true.
    "xcrun": true,

    // Use this compiler path when xcrun is false.
    "metal": "/path/to/metal",

    // Scan the target directory for .metal files. Default: true.
    "find-inputs": true,

    // Add dependency targets as -I paths. Includes product and transitive dependencies.
    "include-dependencies": false,

    // Append a suffix to each dependency include path.
    // This option requires include-dependencies.
    "dependency-path-suffix": "include",

    // Add target-relative -I paths.
    "include-paths": ["Headers", "Metal/Include"],

    // Add input files to those found by directory scanning. Default: [].
    "inputs": ["additional/file.metal"],

    // Set the output file name. Default: default.metallib.
    "output": "default.metallib",

    // Set the module cache directory. Default: the plugin work directory.
    "cache": "/path/to/cache",

    // Use these flags if the selected section omits flags.
    // Existing configurations can keep only this top-level option.
    "flags": ["-DMY_COMMON_METAL_FLAG"],

    "debug": {
        // Override top-level flags for marked debug builds.
        "flags": ["-gline-tables-only", "-frecord-sources"],
    },

    "release": {
        // Override top-level flags when the debug condition is absent.
        "flags": [],
    },

    // Enable plugin logging. Default: false.
    "plugin-logging": false,

    // Add environment, command, input, and output details to plugin logs.
    // This option requires plugin-logging.
    "verbose-logging": false,

    // Add a prefix to each plugin log message.
    "logging-prefix": "[Metal]",

    // Add -fmetal-enable-logging to the compiler flags. Default: false.
    "metal-enable-logging": false,

    // Add environment variables for the Metal compiler. Default: {}.
    "env": {
        "TMPDIR": "/private/tmp"
    },
}
```

## Tricks and Tips

### Create a Pure-Metal Target

A pure-Metal target keeps Metal source and shared headers separate from Swift code. Use this layout:

```text
Sources/MyShaders/
├── Shaders/
│   └── MyShaders.metal
├── include/
│   └── MyShaders.h
├── MyShaders.m
└── metal-compiler-plugin.json
```

`MyShaders.m` can be empty. SwiftPM uses it to recognize the target as a Clang target.

Configure the target in `Package.swift`:

```swift
.target(
    name: "MyShaders",
    exclude: ["Shaders"],
    publicHeadersPath: "include",
    cSettings: [
        .define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))
    ],
    plugins: [
        .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
    ]
)
```

Swift and Metal can now use the same types from `MyShaders.h`. This prevents duplicate declarations and layout differences.

### Produce One Metal Library

SwiftPM compiles recognized `.metal` files into `default.metallib`. The plugin uses the same name, so both build commands conflict.

Keep all Metal files in `Shaders` and exclude that directory from the target:

```swift
.target(
    name: "MyShaders",
    exclude: ["Shaders"],
    plugins: [
        .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
    ]
)
```

The plugin scans excluded directories with `FileManager`, but SwiftPM does not compile their contents. The output bundle contains one `default.metallib`.

Without a common directory, list each `.metal` file in `exclude`. SwiftPM does not support glob patterns in this setting.

### Include Headers from Another Package Target

Declare the header target as a dependency. Use `publicHeadersPath` for each target's local headers:

```swift
.target(
    name: "DependencyShaders",
    publicHeadersPath: "include"
),
.target(
    name: "ExampleShaders",
    dependencies: ["DependencyShaders"],
    exclude: ["Shaders"],
    publicHeadersPath: "include",
    plugins: [
        .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
    ]
)
```

Configure the include paths in `Sources/ExampleShaders/metal-compiler-plugin.json`:

```json5
{
    "include-dependencies": true,
    "dependency-path-suffix": "include",
    "include-paths": ["include"],
}
```

The Metal source can now include local and dependency headers:

```metal
#include "ExampleShaders.h"
#include "DependencyShaders.h"
```

The plugin adds direct, product, and transitive dependency directories as `-I` paths. `dependency-path-suffix` appends `include` to each path.

## License

BSD 3-clause. See [LICENSE.md](LICENSE.md).

