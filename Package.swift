// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetalCompilerPlugin",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .plugin(name: "MetalCompilerPlugin", targets: ["MetalCompilerPlugin"]),
    ],
    targets: [
        .plugin(name: "MetalCompilerPlugin", capability: .buildTool()),
        .target(name: "ExampleShaders", plugins: ["MetalCompilerPlugin"]),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders"]
        ),
    ]
)
