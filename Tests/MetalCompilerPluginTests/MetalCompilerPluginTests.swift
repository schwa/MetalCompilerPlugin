import XCTest

import Metal

final class MetalCompilerPluginTests: XCTestCase {
    func testExample() throws {

        // TODO: This only works under Xcode Unit Tests. But fails when run from `swift test` command line.

        let shadersBundleURL = Bundle(for: MetalCompilerPluginTests.self).resourceURL!.appending(path: "MetalCompilerPlugin_ExampleShaders.bundle")
        let bundle = Bundle(url: shadersBundleURL)!
        let libraryURL = bundle.url(forResource: "debug", withExtension: "metallib")!
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(URL: libraryURL)
        print(library)
    }
}
