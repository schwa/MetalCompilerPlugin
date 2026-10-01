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
        // Xcode copies resource bundles into Contents/Resources; SwiftPM places
        // them next to the containing .xctest/.app bundle. Search both.
        let searchPaths = [resourcePath, bundleURL.deletingLastPathComponent().path]
            .compactMap { $0 }
        let fileManager = FileManager()

        return searchPaths.flatMap { searchPath -> [Bundle] in
            guard let paths = try? fileManager.contentsOfDirectory(atPath: searchPath) else {
                return []
            }
            return paths.filter { $0.hasSuffix(".bundle") }
                .compactMap { Bundle(path: searchPath.appending("/").appending($0)) }
        }
    }

    /// Returns the first child bundle whose name ends with `_<suffix>.bundle`.
    ///
    /// Call this method on the bundle that contains the generated package resource bundles.
    ///
    /// - Parameter suffix: The target-name suffix of the bundle.
    /// - Returns: The matching bundle, or `nil` if no child bundle matches.
    func childBundle(withSuffix suffix: String) -> Bundle? {
        childBundles.first {
            $0.bundleURL.lastPathComponent.hasSuffix(("_\(suffix).bundle"))
        }
    }
}

