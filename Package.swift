// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "MetalCompilerPlugin",
    products: [
        .plugin(
            name: "MetalCompilerPlugin",
            targets: ["MetalCompilerPlugin"]
        )
    ],
    targets: [
        .plugin(
            name: "MetalCompilerPlugin",
            capability: .buildTool()
        ),

        // The following targets are for testing the plugin and are examples of its usage.
        .target(
            name: "DependencyShaders",
            publicHeadersPath: ".",
            plugins: ["MetalCompilerPlugin"]
        ),
        .target(
            name: "ExampleShaders",
            dependencies: ["DependencyShaders"],
            publicHeadersPath: ".",
            plugins: ["MetalCompilerPlugin"]
        ),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders"],
            resources: [.copy("Empty.txt")]
        )
    ]
)
