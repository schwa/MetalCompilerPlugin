import Foundation
import os
@preconcurrency import PackagePlugin

@main
struct MetalPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true

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

        let command = metalCompiler.buildCommand(context: context, target: target)
        return [command]
    }
}

struct MetalCompiler: Decodable {

    struct Configuration: Decodable {
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

        let useXcrun: Bool
        let metalPath: String?
        let scanInputsInDirectory: Bool
        let inputs: [String]
        let output: String
        let cache: String?
        let extraFlags: [String]?
        let pluginLogging: Bool
        let metalEnableLogging: Bool
        let extraEnvironment: [String: String]?

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            useXcrun = try container.decodeIfPresent(Bool.self, forKey: .useXcrun) ?? true
            metalPath = try container.decodeIfPresent(String.self, forKey: .metalPath)
            scanInputsInDirectory = try container.decodeIfPresent(Bool.self, forKey: .scanInputsInDirectory) ?? true
            inputs = try container.decodeIfPresent([String].self, forKey: .inputs) ?? []
            output = try container.decodeIfPresent(String.self, forKey: .output) ?? "debug.metallib"
            cache = try container.decodeIfPresent(String.self, forKey: .cache)
            extraFlags = try container.decodeIfPresent([String].self, forKey: .extraFlags)
            pluginLogging = try container.decodeIfPresent(Bool.self, forKey: .pluginLogging) ?? false
            metalEnableLogging = try container.decodeIfPresent(Bool.self, forKey: .metalEnableLogging) ?? false
            extraEnvironment = try container.decodeIfPresent([String: String].self, forKey: .extraEnvironment)
        }
    }

    let config: Configuration

    init(from decoder: any Decoder) throws {
        config = try Configuration(from: decoder)
    }

    func buildCommand(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) -> PackagePlugin.Command {
        let logger: ((String) -> Void)? = config.pluginLogging ? { (string: String) in
            Diagnostics.remark(string)
        } : nil

        if config.pluginLogging {
            logger?("Input environment:")
            for (key, value) in ProcessInfo.processInfo.environment.sorted(by: { $0.key < $1.key }) {
                logger?("\t\(key): \(value)")
            }
        }

        let executable: String
        var arguments: [String]

        if config.useXcrun {
            executable = "/usr/bin/xcrun"
            arguments = ["metal"]
            logger?("Using 'xcrun' to find the metal compiler.")
        }
        else {
            guard let metalPath = config.metalPath else {
                fatalError("metalPath is required when xcrun is disabled")
            }
            executable = metalPath
            arguments = []
            logger?("Using metal compiler at '\(metalPath)'.")
        }

        if let extraFlags = config.extraFlags {
            arguments += extraFlags
            logger?("Using extra flags: \(extraFlags.joined(separator: " "))")
        }
        else {
            arguments += ["-gline-tables-only", "-frecord-sources"]
            logger?("Using default flags: -gline-tables-only -frecord-sources")
        }

        if config.metalEnableLogging {
            arguments += ["-fmetal-enable-logging"]
            logger?("Enabling metal logging.")
        }

        // Cache Directory
        let cache = config.cache ?? context.pluginWorkDirectory.appending(["cache"]).string
        arguments += [ "-fmodules-cache-path=\(cache)" ]
        logger?("Using cache directory: \(cache)")

        // Input (sources)
        var inputs: [String] = []
        if config.scanInputsInDirectory {
            inputs += target.findFiles(withPathExtension: "metal")
        }
        inputs += config.inputs
        arguments += inputs
        logger?("Using input files: \(inputs.joined(separator: ", "))")

        logger?("Using output file: \(config.output)")
        let output = context.pluginWorkDirectory.appending([config.output])
        arguments += ["-o", output.string]

        var environment: [String: String] = [:]
        environment["TMPDIR"] = "/private/tmp"
        logger?("Using custom temporary directory: '/private/tmp'")

        if config.pluginLogging {
            logger?("Build command environment variables:")
            for (key, value) in environment.sorted(by: { $0.key < $1.key }) {
                logger?("\t\(key): \(value)")
            }
        }

        return .buildCommand(
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

