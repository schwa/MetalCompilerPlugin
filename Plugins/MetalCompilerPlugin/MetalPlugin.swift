import Foundation
import os
import PackagePlugin

@main
struct MetalPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {

//        print("CurrentDirectoryPath", FileManager().currentDirectoryPath)
//        print("PluginWorkDirectory", context.pluginWorkDirectory.string)
//        print("TargetDirectory", target.directory.string)

        let metalCompiler: MetalCompiler
        if let data = try? Data(contentsOf: target.directory.appending([".metal-compiler-plugin.json"]).url) {
            let decoder = JSONDecoder()
            decoder.allowsJSON5 = true
            metalCompiler = try decoder.decode(MetalCompiler.self, from: data, configuration: (context, target))
        }
        else {
            metalCompiler = MetalCompiler(context: context, target: target)
        }

        Diagnostics.remark("Running...")
        return [metalCompiler.command]
    }
}

struct MetalCompiler: DecodableWithConfiguration {

    enum CodingKeys: CodingKey {
        case useXcrun
        case metalPath
        case scanInputsInDirectory
        case inputs
        case output
        case cache
        case extraFlags
    }

    var command: PackagePlugin.Command

    init(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) {
        print("DEFAULT")
        let cache = context.pluginWorkDirectory.appending(["cache"]).string
        let inputs = target.findFiles(withPathExtension: "metal")
        let output = context.pluginWorkDirectory.appending(["debug.metallib"])
        command = .buildCommand(
            displayName: "metal",
            executable: Path("/usr/bin/xcrun"),
            arguments: ["metal", "-gline-tables-only", "-frecord-sources", "-fmodules-cache-path=\(cache)", "-o", output.string],
            environment: [:],
            inputFiles: inputs,
            outputFiles: [output]
        )


    }

    init(from decoder: any Decoder, configuration: (context: PackagePlugin.PluginContext, target: PackagePlugin.Target)) throws {
        let (context, target) = configuration

        let executable: Path
        var arguments: [String]

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let useXcrun = try container.decodeIfPresent(Bool.self, forKey: .useXcrun) ?? true
        if useXcrun {
            executable = Path("/usr/bin/xcrun")
            arguments = ["metal"]
        }
        else {
            let metalPath = try container.decode(String.self, forKey: .metalPath)
            executable = Path(metalPath)
            arguments = []
        }

        if let extraFlags = try container.decodeIfPresent([String].self, forKey: .extraFlags) {
            arguments += extraFlags
        }
        else {
            arguments += ["-gline-tables-only", "-frecord-sources"]
        }

        // Cache Directory
        let cache = try container.decodeIfPresent(String.self, forKey: .cache) ?? context.pluginWorkDirectory.appending(["cache"]).string
        arguments += [ "-fmodules-cache-path=\(cache)" ]

        // Input (sources)
        let scanInputsInDirectory = try container.decodeIfPresent(Bool.self, forKey: .scanInputsInDirectory) ?? true
        var inputs: [Path] = []
        if scanInputsInDirectory {
            inputs += target.findFiles(withPathExtension: "metal")
        }
        inputs += (try container.decodeIfPresent([String].self, forKey: .inputs) ?? []).map { Path($0) }
        arguments += inputs.map(\.string)

        let outputName = try container.decodeIfPresent(String.self, forKey: .output) ?? "debug.metallib"
        let output = context.pluginWorkDirectory.appending([outputName])
        arguments += ["-o", output.string]

        command = .buildCommand(
            displayName: "metal",
            executable: executable,
            arguments: arguments,
            environment: [:],
            inputFiles: inputs,
            outputFiles: [output]
        )
    }
}

extension PackagePlugin.Target {
    func findFiles(withPathExtension extension: String) -> [Path] {
        let errorHandler = { (_: URL, _: Swift.Error) -> Bool in
            true
        }
        guard let enumerator = FileManager().enumerator(at: directory.url, includingPropertiesForKeys: nil, options: [], errorHandler: errorHandler) else {
            fatalError()
        }
        var paths: [Path] = []
        for url in enumerator {
            guard let url = url as? URL else {
                fatalError()
            }
            if url.pathExtension == `extension` {
                let path = Path(url.path)
                paths.append(path)
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
