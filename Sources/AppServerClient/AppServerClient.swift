#if os(macOS)
import Darwin
import Dispatch
import Foundation

public struct AppServerSmokeRunner {
    public init() {}

    public func run() throws -> Int32 {
        let process = Process()
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["codex", "app-server"]
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        let signalSources = installTerminationHandlers(for: process)
        defer {
            signalSources.forEach { $0.cancel() }
            if process.isRunning {
                process.terminate()
            }
        }

        forwardStderr(from: stderr.fileHandleForReading)
        try sendInitialize(to: stdin.fileHandleForWriting)
        readMessages(from: stdout.fileHandleForReading)

        process.waitUntilExit()
        return process.terminationStatus
    }

    private func installTerminationHandlers(for process: Process) -> [DispatchSourceSignal] {
        [SIGINT, SIGTERM].map { signalNumber in
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(
                signal: signalNumber,
                queue: DispatchQueue.global(qos: .userInitiated)
            )
            source.setEventHandler {
                if process.isRunning {
                    process.terminate()
                }
                Darwin.exit(128 + signalNumber)
            }
            source.resume()
            return source
        }
    }

    private func sendInitialize(to handle: FileHandle) throws {
        let params = Components.Schemas.InitializeParams(
            capabilities: Components.Schemas.InitializeCapabilities(
                experimentalApi: true
            ),
            clientInfo: Components.Schemas.ClientInfo(
                name: "swift-appserver-client",
                title: "Swift AppServer Client",
                version: "0.0.0"
            )
        )
        let request = AppServerModels.ClientRequest.Initialize.build(
            id: Components.Schemas.RequestId(value2: 1),
            params: params
        )
        let encoded = try JSONEncoder().encode(request)
        handle.write(encoded)
        handle.write(Data([0x0A]))
    }

    private func readMessages(from handle: FileHandle) {
        let decoder = JSONDecoder()
        while let line = readLine(from: handle) {
            guard let data = line.data(using: .utf8) else {
                print("unreadable: \(line)")
                continue
            }

            if let response = try? decoder.decode(InitializeJSONRPCResponse.self, from: data) {
                print("initialize-response: \(response.result)")
            } else if let request = try? decoder.decode(AppServerModels.ServerRequest.self, from: data) {
                print("server-request: \(request)")
            } else if let notification = try? decoder.decode(AppServerModels.ServerNotification.self, from: data) {
                print("server-notification: \(notification)")
            } else if let pretty = prettyPrintedJSON(data) {
                print("json: \(pretty)")
            } else {
                print("unparsed: \(line)")
            }
        }
    }

    private func forwardStderr(from handle: FileHandle) {
        DispatchQueue.global(qos: .utility).async {
            while let line = readLine(from: handle) {
                FileHandle.standardError.write(Data(line.utf8))
                FileHandle.standardError.write(Data([0x0A]))
            }
        }
    }

    private func prettyPrintedJSON(_ data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            JSONSerialization.isValidJSONObject(object),
            let prettyData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
            )
        else {
            return nil
        }
        return String(data: prettyData, encoding: .utf8)
    }
}

private struct InitializeJSONRPCResponse: Decodable {
    let id: Components.Schemas.RequestId
    let result: Components.Schemas.InitializeResponse
}

private func readLine(from handle: FileHandle) -> String? {
    var data = Data()
    while true {
        let byte = handle.readData(ofLength: 1)
        if byte.isEmpty {
            return data.isEmpty ? nil : String(data: data, encoding: .utf8)
        }
        if byte[byte.startIndex] == 0x0A {
            return String(data: data, encoding: .utf8)
        }
        data.append(byte)
    }
}
#endif
