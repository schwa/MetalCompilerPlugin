import Testing
import Metal
import Foundation

@Test
func testMetalCompilerPlugin() throws {

//     TODO: This only works under Xcode Unit Tests. But fails when run from `swift test` command line.

    let shadersBundleURL = Bundle.module.bundleURL.appendingPathComponent("../MetalCompilerPlugin_ExampleShaders.bundle")
//    print(shadersBundleURL)
    let bundle = Bundle(url: shadersBundleURL)!
    let libraryURL = bundle.url(forResource: "debug", withExtension: "metallib")!
    let device = MTLCreateSystemDefaultDevice()!
    let library = try device.makeLibrary(URL: libraryURL)
    print(library)
}

