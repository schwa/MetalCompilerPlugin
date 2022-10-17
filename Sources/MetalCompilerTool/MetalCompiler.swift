import ArgumentParser
import Foundation
import os

@main
struct MetalCompilerTool: ParsableCommand {
    @Option(name: .shortAndLong)
    var output: String

    @Argument
    var inputs: [String]

    mutating func run() throws {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        p.arguments = [
            "metal",
        ]
            + inputs
            + [
                "-o",
                output,
                "-gline-tables-only",
                "-frecord-sources",
            ]
        try p.run()
    }
}
