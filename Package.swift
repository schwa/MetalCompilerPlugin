// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetalCompilerPlugin",
    products: [
        .plugin(name: "MetalCompilerPlugin", targets: ["MetalCompilerPlugin"]),
    ],
    targets: [
        .plugin(name: "MetalCompilerPlugin", capability: .buildTool()),
        .target(name: "ExampleShaders", plugins: ["MetalCompilerPlugin"]),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders"],
            resources: [.copy("Empty.txt")]
        ),
    ]
)
