import Foundation

#if os(macOS)
import Darwin
#elseif os(Linux)
import Linux
#else
#error("Unsupported platform")
#endif

public final actor StdIOAppServerConnection: AppServerConnection {
    private let process: Process
    private let signalSources: [DispatchSourceSignal]
    private var readFileHandle: FileHandle
    private var writeFileHandle: FileHandle

    public static func connect() throws -> StdIOAppServerConnection {
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

        forwardStderr(from: stderr.fileHandleForReading)

        return StdIOAppServerConnection(
            process: process,
            signalSources: signalSources,
            readFileHandle: stdout.fileHandleForReading,
            writeFileHandle: stdin.fileHandleForWriting
        )
    }

    private static func installTerminationHandlers(for process: Process) -> [DispatchSourceSignal] {
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

    private static func readLine(from handle: FileHandle) -> String? {
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

    private static func forwardStderr(from handle: FileHandle) {
        DispatchQueue.global(qos: .utility).async {
            while let line = readLine(from: handle) {
                FileHandle.standardError.write(Data(line.utf8))
                FileHandle.standardError.write(Data([0x0A]))
            }
        }
    }

    init(
        process: Process,
        signalSources: [DispatchSourceSignal],
        readFileHandle: FileHandle,
        writeFileHandle: FileHandle
    ) {
        self.process = process
        self.signalSources = signalSources
        self.readFileHandle = readFileHandle
        self.writeFileHandle = writeFileHandle
    }

    deinit {
        signalSources.forEach { $0.cancel() }
        if process.isRunning {
            process.terminate()
        }
    }

    public var reader: AsyncStream<Data> {
        .init(bufferingPolicy: .unbounded) { continuation in
            // TODO: Fix this
            let newReadFileHandle = readFileHandle.copy() as! FileHandle
            Task {
                while let line = Self.readLine(from: newReadFileHandle) {
                    guard let data = line.data(using: .utf8) else {
                        print("unreadable: \(line)")
                        continue
                    }
                    try Task.checkCancellation()
                    continuation.yield(data)
                }
                continuation.finish()
            }
        }
    }

    public func write(_ data: Data) async throws {
        writeFileHandle.write(data)
        writeFileHandle.write(Data([0x0A]))
    }
}
