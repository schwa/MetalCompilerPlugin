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
}

