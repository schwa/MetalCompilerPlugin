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
            case includeDependencies = "include-dependencies"
            case dependencyPathSuffix = "dependency-path-suffix"
            case inputs = "inputs"
            case output = "output"
            case cache = "cache"
            case extraFlags = "flags"
            case pluginLogging = "plugin-logging"
            case verboseLogging = "verbose-logging"
            case metalEnableLogging = "metal-enable-logging"
            case extraEnvironment = "env"
            case loggingPrefix = "logging-prefix"
        }

        var useXcrun: Bool = true
        var metalPath: String?
        var scanInputsInDirectory: Bool = true
        var includeDependencies: Bool = false
        var dependencyPathSuffix: String?
        var inputs: [String]
        var output: String = "debug.metallib"
        var cache: String?
        var extraFlags: [String]?
        var pluginLogging: Bool = false
        var verboseLogging: Bool = false
        var metalEnableLogging: Bool = false
        var extraEnvironment: [String: String]?
        var loggingPrefix: String?

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            useXcrun = try container.decodeIfPresent(Bool.self, forKey: .useXcrun) ?? true
            metalPath = try container.decodeIfPresent(String.self, forKey: .metalPath)
            scanInputsInDirectory = try container.decodeIfPresent(Bool.self, forKey: .scanInputsInDirectory) ?? true
            includeDependencies = try container.decodeIfPresent(Bool.self, forKey: .includeDependencies) ?? false
            dependencyPathSuffix = try container.decodeIfPresent(String.self, forKey: .dependencyPathSuffix)
            inputs = try container.decodeIfPresent([String].self, forKey: .inputs) ?? []
            output = try container.decodeIfPresent(String.self, forKey: .output) ?? "debug.metallib"
            cache = try container.decodeIfPresent(String.self, forKey: .cache)
            extraFlags = try container.decodeIfPresent([String].self, forKey: .extraFlags)
            pluginLogging = try container.decodeIfPresent(Bool.self, forKey: .pluginLogging) ?? false
            verboseLogging = try container.decodeIfPresent(Bool.self, forKey: .verboseLogging) ?? false
            metalEnableLogging = try container.decodeIfPresent(Bool.self, forKey: .metalEnableLogging) ?? false
            extraEnvironment = try container.decodeIfPresent([String: String].self, forKey: .extraEnvironment)
            loggingPrefix = try container.decodeIfPresent(String.self, forKey: .loggingPrefix)
        }
    }

    let config: Configuration

    init(from decoder: any Decoder) throws {
        config = try Configuration(from: decoder)
    }

    func buildCommand(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) -> PackagePlugin.Command {
        let prefix = config.loggingPrefix.map { $0 + " " } ?? ""

        let logger: ((String) -> Void)? = config.pluginLogging ? { (string: String) in
            Diagnostics.remark(prefix + string)
        } : nil

        let verbose: ((String) -> Void)? = config.pluginLogging && config.verboseLogging ? { (string: String) in
            Diagnostics.remark(prefix + string)
        } : nil

        logger?("Current working directory: \(FileManager.default.currentDirectoryPath)")

        verbose?("Input environment:")
        if config.pluginLogging && config.verboseLogging {
            for (key, value) in ProcessInfo.processInfo.environment.sorted(by: { $0.key < $1.key }) {
                verbose?("\t\(key): \(value)")
            }
        }

        let executable: String
        var arguments: [String]

        if config.useXcrun {
            executable = "/usr/bin/xcrun"
            arguments = ["metal"]
            logger?("Using xcrun to find metal compiler")
        }
        else {
            guard let metalPath = config.metalPath else {
                fatalError("metalPath is required when xcrun is disabled")
            }
            executable = metalPath
            arguments = []
            logger?("Using metal compiler at '\(metalPath)'")
        }

        if let extraFlags = config.extraFlags {
            arguments += extraFlags
            verbose?("Extra flags: \(extraFlags.joined(separator: " "))")
        }
        else {
            arguments += ["-gline-tables-only", "-frecord-sources"]
            verbose?("Default flags: -gline-tables-only -frecord-sources")
        }

        if config.metalEnableLogging {
            arguments += ["-fmetal-enable-logging"]
            logger?("Metal logging enabled")
        }

        // Cache Directory
        let cache = config.cache ?? context.pluginWorkDirectory.appending(["cache"]).string
        arguments += [ "-fmodules-cache-path=\(cache)" ]
        verbose?("Cache directory: \(cache)")

        // Dependencies
        if config.includeDependencies {
            logger?("Including \(target.dependencies.count) dependency include path(s)")
            for dependency: TargetDependency in target.dependencies {
                switch dependency {
                case .product:
                    Diagnostics.error("Product dependencies are not supported for include paths in MetalCompilerPlugin.")
                case .target(let target):
                    let includePath: String
                    if let suffix = config.dependencyPathSuffix {
                        includePath = target.directory.appending([suffix]).string
                    } else {
                        includePath = target.directory.string
                    }
                    verbose?("  -I \(includePath)")
                    arguments += ["-I", includePath]
                @unknown default:
                    Diagnostics.error("Unknown dependency type in MetalCompilerPlugin.")
                }
            }
        }

        // Input (sources)
        var inputs: [String] = []
        if config.scanInputsInDirectory {
            inputs += target.findFiles(withPathExtension: "metal")
        }
        inputs += config.inputs
        arguments += inputs
        logger?("Compiling \(inputs.count) input file(s)")
        verbose?("Input files: \(inputs.joined(separator: ", "))")

        logger?("Output: \(config.output)")
        let output = context.pluginWorkDirectory.appending([config.output])
        arguments += ["-o", output.string]

        var environment: [String: String] = [:]
        environment["TMPDIR"] = "/private/tmp"
        verbose?("Custom TMPDIR: /private/tmp")

        arguments += ["-DMETAL"]

        verbose?("Build command environment:")
        if config.pluginLogging && config.verboseLogging {
            for (key, value) in environment.sorted(by: { $0.key < $1.key }) {
                verbose?("\t\(key): \(value)")
            }
        }

        verbose?("Command: \(executable) \(arguments.joined(separator: " "))")


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

