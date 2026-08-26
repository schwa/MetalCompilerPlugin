import Testing
import Metal
import Foundation

@Test
func `builds one default library from an excluded shader directory`() throws {
    let shadersBundleURL = Bundle.module.bundleURL.appendingPathComponent("../MetalCompilerPlugin_ExampleShaders.bundle")
    let bundle = try #require(Bundle(url: shadersBundleURL))
    let libraryURLs = bundle.urls(forResourcesWithExtension: "metallib", subdirectory: nil) ?? []

    #expect(libraryURLs.map(\.lastPathComponent) == ["default.metallib"])

    let device = try #require(MTLCreateSystemDefaultDevice())
    let libraryURL = try #require(libraryURLs.first)
    let library = try device.makeLibrary(URL: libraryURL)

    #expect(library.functionNames.contains("k"))

    #if METAL_COMPILER_PLUGIN_DEBUG
    #expect(library.functionNames.contains("configurationDebug"))
    #expect(!library.functionNames.contains("configurationRelease"))
    #else
    #expect(library.functionNames.contains("configurationRelease"))
    #expect(!library.functionNames.contains("configurationDebug"))
    #endif
}

@Test
func `top-level flags apply to every configuration`() throws {
    let shadersBundleURL = Bundle.module.bundleURL.appendingPathComponent("../MetalCompilerPlugin_DependencyShaders.bundle")
    let bundle = try #require(Bundle(url: shadersBundleURL))
    let libraryURL = try #require(bundle.url(forResource: "default", withExtension: "metallib"))
    let device = try #require(MTLCreateSystemDefaultDevice())
    let library = try device.makeLibrary(URL: libraryURL)

    #expect(library.functionNames.contains("commonFlags"))
}

