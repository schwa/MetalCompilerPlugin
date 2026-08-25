// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "MetalCompilerPlugin",
    products: [
        .plugin(
            name: "MetalCompilerPlugin",
            targets: ["MetalCompilerPlugin"]
        ),
        .library(name: "MetalCompilerPluginSupport", targets: ["MetalCompilerPluginSupport"]),
    ],
    targets: [
        .plugin(
            name: "MetalCompilerPlugin",
            capability: .buildTool()
        ),
        .target(
            name: "MetalCompilerPluginSupport"
        ),

        // The following targets are for testing the plugin and are examples of its usage.
        .target(
            name: "DependencyShaders",
            exclude: ["DependencyShaders.metal"],
            publicHeadersPath: ".",
            cSettings: [.define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))],
            plugins: ["MetalCompilerPlugin"]
        ),
        .target(
            name: "ExampleShaders",
            dependencies: ["DependencyShaders"],
            exclude: ["ExampleShaders.metal"],
            publicHeadersPath: ".",
            cSettings: [.define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))],
            plugins: ["MetalCompilerPlugin"]
        ),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders"],
            resources: [.copy("Empty.txt")]
        )
    ]
)
