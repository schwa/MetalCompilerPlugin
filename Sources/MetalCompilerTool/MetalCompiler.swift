import Foundation
import os

@main
struct MetalCompilerTool {
    static func main() {
        let args = CommandLine.arguments.dropFirst() // Skip program name

        var output: String?
        var cache: String?
        var inputs: [String] = []

        var i = args.startIndex
        while i < args.endIndex {
            let arg = args[i]

            switch arg {
            case "--output":
                i = args.index(after: i)
                if i < args.endIndex {
                    output = args[i]
                }
            case "--cache":
                i = args.index(after: i)
                if i < args.endIndex {
                    cache = args[i]
                }
            default:
                inputs.append(arg)
            }

            i = args.index(after: i)
        }

        guard let outputPath = output, let cachePath = cache, !inputs.isEmpty else {
            print("Usage: --output <output_path> --cache <cache_path> <input_files...>")
            exit(1)
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        p.environment = ["TMPDIR": "/private/tmp"]
        p.arguments = [
            "metal",
        ] + inputs + [
            "-o", outputPath,
            "-gline-tables-only",
            "-frecord-sources",
            "-fmodules-cache-path=\(cachePath)"
        ]

        do {
            try p.run()
            p.waitUntilExit()
            if p.terminationStatus != 0 {
                print("Error: metal compiler exited with code \(p.terminationStatus)")
                exit(p.terminationStatus)
            }
        } catch {
            print("Failed to run metal compiler: \(error)")
            exit(1)
        }
    }
}
