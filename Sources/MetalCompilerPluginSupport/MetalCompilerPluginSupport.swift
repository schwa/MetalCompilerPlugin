import Foundation

public extension Bundle {
    var parentBundle: Bundle? {
        let components = bundlePath.split(separator: "/")
        guard let index = components.dropLast().firstIndex(where: { $0.hasSuffix(".bundle") || $0.hasSuffix(".xctest") || $0.hasSuffix(".app") }) else {
            return nil
        }
        let path = "/" + components[...index].joined(separator: "/")
        return Bundle(path: path)
    }

    var childBundles: [Bundle] {
        guard let resourcePath else {
            return []
        }
        let fileManager = FileManager()
        guard let paths = try? fileManager.contentsOfDirectory(atPath: resourcePath) else {
            return []
        }

        return paths.filter {
            $0.hasSuffix(".bundle")
        }
        .map {
            Bundle(path: resourcePath.appending("/").appending($0))!
        }
    }

    /// Looks for a child bundle with a name of the form: `"*_<suffix>.bundle"`. Use like `Bundle.module.parentBundle?.childBundle(withSuffix: "<target name>")` to help find a bundle with shaders
    func childBundle(withSuffix suffix: String) -> Bundle? {
        childBundles.first {
            $0.bundleURL.lastPathComponent.hasSuffix(("_\(suffix).bundle"))
        }
    }
}

