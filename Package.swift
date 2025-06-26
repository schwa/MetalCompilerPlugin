// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "MetalCompilerPlugin",
    products: [
        .plugin(
            name: "MetalCompilerPlugin",
            targets: ["MetalCompilerPlugin"]
        ),
    ],
    targets: [
        .plugin(
            name: "MetalCompilerPlugin",
            capability: .buildTool()
        ),
        .target(
            name: "ExampleShaders",
            resources: [.copy("Empty.txt")],
            plugins: ["MetalCompilerPlugin"]
        ),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders"],
            resources: [.copy("Empty.txt")]
        ),
    ]
)
