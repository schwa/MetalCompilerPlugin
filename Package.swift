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
            exclude: ["Shaders"],
            publicHeadersPath: "include",
            cSettings: [.define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))],
            plugins: ["MetalCompilerPlugin"]
        ),
        .target(
            name: "ExampleShaders",
            dependencies: ["DependencyShaders"],
            exclude: ["Shaders"],
            publicHeadersPath: "include",
            cSettings: [.define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))],
            plugins: ["MetalCompilerPlugin"]
        ),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders", "MetalCompilerPluginSupport"],
            swiftSettings: [.define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))]
        )
    ]
)
