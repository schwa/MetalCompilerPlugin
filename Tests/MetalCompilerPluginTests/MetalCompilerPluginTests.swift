import Testing
import Metal
import MetalCompilerPluginSupport
import Foundation

private final class ShaderBundleToken {
    static let bundle = Bundle(for: ShaderBundleToken.self)
}

private enum ShaderLibraryError: Error {
    case metalUnavailable
    case shaderBundleNotFound
}

private func loadShaderLibrary(from containingBundle: Bundle, targetName: String) throws -> any MTLLibrary {
    guard let device = MTLCreateSystemDefaultDevice() else {
        throw ShaderLibraryError.metalUnavailable
    }
    guard let shaderBundle = containingBundle.childBundle(withSuffix: targetName) else {
        throw ShaderLibraryError.shaderBundleNotFound
    }
    return try device.makeDefaultLibrary(bundle: shaderBundle)
}

@Test
func `builds one default library from an excluded shader directory`() throws {
    let containingBundle = ShaderBundleToken.bundle
    let bundle = try #require(containingBundle.childBundle(withSuffix: "ExampleShaders"))
    let libraryURLs = bundle.urls(forResourcesWithExtension: "metallib", subdirectory: nil) ?? []

    #expect(libraryURLs.map(\.lastPathComponent) == ["default.metallib"])

    let library = try loadShaderLibrary(from: containingBundle, targetName: "ExampleShaders")

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
    let containingBundle = ShaderBundleToken.bundle
    let library = try loadShaderLibrary(from: containingBundle, targetName: "DependencyShaders")

    #expect(library.functionNames.contains("commonFlags"))
}

