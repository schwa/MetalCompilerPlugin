// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HostShaders",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "HostShaders", targets: ["ShadersA", "ShadersB"]),
    ],
    dependencies: [
        // matrix.sh symlinks the repository here.
        .package(path: "../MetalCompilerPlugin"),
    ],
    targets: [
        .target(
            name: "ShadersA",
            exclude: ["Shaders"],
            swiftSettings: [.define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))],
            plugins: [.plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")]
        ),
        .target(
            name: "ShadersB",
            exclude: ["Shaders"],
            swiftSettings: [.define("METAL_COMPILER_PLUGIN_DEBUG", .when(configuration: .debug))],
            plugins: [.plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")]
        ),
    ]
)
