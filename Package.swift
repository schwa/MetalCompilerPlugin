// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetalCompilerPlugin",
    products: [
        .plugin(name: "MetalCompilerPlugin", targets: ["MetalCompilerPlugin"]),
        .executable(name: "MetalCompilerTool", targets: ["MetalCompilerTool"]),
    ],
    dependencies: [
    ],
    targets: [
        .plugin(name: "MetalCompilerPlugin", capability: .buildTool(), dependencies: ["MetalCompilerTool"]),
        .executableTarget(name: "MetalCompilerTool"),
        .target(name: "ExampleShaders", plugins: ["MetalCompilerPlugin"]),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders"]
        ),
    ]
)
