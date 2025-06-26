import Foundation
import os
@preconcurrency import PackagePlugin

extension CodingUserInfoKey {
    static let context = CodingUserInfoKey(rawValue: "context")!
    static let target = CodingUserInfoKey(rawValue: "target")!
}

@main
struct MetalPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        decoder.userInfo[.context] = context
        decoder.userInfo[.target] = target
        let metalCompiler: MetalCompiler
        if let data = try? Data(contentsOf: target.directory.appending(["metal-compiler-plugin.json"]).url) {
            Diagnostics.remark("Using configuration from 'metal-compiler-plugin.json'")
            metalCompiler = try decoder.decode(MetalCompiler.self, from: data)
        } else if let data = try? Data(contentsOf: target.directory.appending([".metal-compiler-plugin.json"]).url) {
            Diagnostics.remark("Using configuration from '.metal-compiler-plugin.json'")
            metalCompiler = try decoder.decode(MetalCompiler.self, from: data)
        } else {
            Diagnostics.remark("Using default configuration for MetalCompiler")
            let data = "{}".data(using: .utf8)!
            metalCompiler = try decoder.decode(MetalCompiler.self, from: data)
        }
        return [metalCompiler.command]
    }
}

struct MetalCompiler: Decodable {

    enum CodingKeys: String, CodingKey {
        case useXcrun = "xcrun"
        case metalPath = "metal"
        case scanInputsInDirectory = "find-inputs"
        case inputs = "inputs"
        case output = "output"
        case cache = "cache"
        case extraFlags = "flags"
        case pluginLogging = "plugin-logging"
        case metalEnableLogging = "metal-enable-logging"
        case extraEnvironment = "env"
    }

    var command: PackagePlugin.Command

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let context = decoder.userInfo[.context] as! PackagePlugin.PluginContext
        let target = decoder.userInfo[.target] as! PackagePlugin.Target


        let pluginLogging = try container.decodeIfPresent(Bool.self, forKey: .pluginLogging) ?? false
        let logger: ((String) -> Void)? = pluginLogging ? { (string: String) in
            Diagnostics.remark(string)
        } : nil

        if pluginLogging {
            logger?("Input environment:")
            for (key, value) in ProcessInfo.processInfo.environment.sorted(by: { $0.key < $1.key }) {
                logger?("\t\(key): \(value)")
            }
        }

        let executable: String
        var arguments: [String]

        let useXcrun = try container.decodeIfPresent(Bool.self, forKey: .useXcrun) ?? true
        if useXcrun {
            executable = "/usr/bin/xcrun"
            arguments = ["metal"]
            logger?("Using 'xcrun' to find the metal compiler.")
        }
        else {
            let metalPath = try container.decode(String.self, forKey: .metalPath)
            executable = metalPath
            arguments = []
            logger?("Using metal compiler at '\(metalPath)'.")
        }

        if let extraFlags = try container.decodeIfPresent([String].self, forKey: .extraFlags) {
            arguments += extraFlags
            logger?("Using extra flags: \(extraFlags.joined(separator: " "))")
        }
        else {
            arguments += ["-gline-tables-only", "-frecord-sources"]
            logger?("Using default flags: -gline-tables-only -frecord-sources")
        }

        if let metalEnableLogging = try container.decodeIfPresent(Bool.self, forKey: .metalEnableLogging), metalEnableLogging {
            arguments += ["-fmetal-enable-logging"]
            logger?("Enabling metal logging.")
        }

        // Cache Directory
        let cache = try container.decodeIfPresent(String.self, forKey: .cache) ?? context.pluginWorkDirectory.appending(["cache"]).string
        arguments += [ "-fmodules-cache-path=\(cache)" ]
        logger?("Using cache directory: \(cache)")

        // Input (sources)
        let scanInputsInDirectory = try container.decodeIfPresent(Bool.self, forKey: .scanInputsInDirectory) ?? true
        var inputs: [String] = []
        if scanInputsInDirectory {
            inputs += target.findFiles(withPathExtension: "metal")
        }
        inputs += (try container.decodeIfPresent([String].self, forKey: .inputs) ?? [])
        arguments += inputs
        logger?("Using input files: \(inputs.joined(separator: ", "))")

        let outputName = try container.decodeIfPresent(String.self, forKey: .output) ?? "debug.metallib"
        logger?("Using output file: \(outputName)")
        let output = context.pluginWorkDirectory.appending([outputName])
        arguments += ["-o", output.string]

        var environment: [String: String] = [:]
        environment["TMPDIR"] = "/private/tmp"
        logger?("Using custom temporary directory: '/private/tmp'")

        if pluginLogging {
            logger?("Build command environment variables:")
            for (key, value) in environment.sorted(by: { $0.key < $1.key }) {
                logger?("\t\(key): \(value)")
            }
        }

        command = .buildCommand(
            displayName: "metal",
            executable: Path(executable),
            arguments: arguments,
            environment: environment,
            inputFiles: inputs.map { Path($0) },
            outputFiles: [output]
        )
    }
}

extension PackagePlugin.Target {
    func findFiles(withPathExtension extension: String) -> [String] {
        let errorHandler = { (_: URL, _: Swift.Error) -> Bool in
            true
        }
        guard let enumerator = FileManager().enumerator(at: directory.url, includingPropertiesForKeys: nil, options: [], errorHandler: errorHandler) else {
            fatalError()
        }
        var paths: [String] = []
        for url in enumerator {
            guard let url = url as? URL else {
                fatalError()
            }
            if url.pathExtension == `extension` {
                paths.append(url.path)
            }
        }
        return paths
    }
}

extension Path {
    var url: URL {
        URL(fileURLWithPath: string)
    }

    var pathExtension: String {
        url.pathExtension
    }
}

