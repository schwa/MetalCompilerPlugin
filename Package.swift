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
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .plugin(name: "MetalCompilerPlugin", capability: .buildTool(), dependencies: ["MetalCompilerTool"]),
        .executableTarget(name: "MetalCompilerTool", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "ExampleShaders", plugins: ["MetalCompilerPlugin"]),
        .testTarget(
            name: "MetalCompilerPluginTests",
            dependencies: ["ExampleShaders"]
        ),
    ]
)
