import Foundation
import Testing
@testable import AppServerClient

@Test func requestIdValueConvertsStringIds() async throws {
    let id = AppServerModels.ID.string("request-1")

    #expect(id == .string("request-1"))
}

@Test func requestIdValueConvertsIntegerIds() async throws {
    let id = AppServerModels.ID.integer(42)

    #expect(id == .integer(42))
}

@Test func requestIdValueRoundTripsThroughGeneratedRequestId() async throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let stringData = try encoder.encode(AppServerModels.ID.string("request-1"))
    let stringId = try decoder.decode(AppServerModels.ID.self, from: stringData)
    #expect(String(data: stringData, encoding: .utf8) == "\"request-1\"")
    #expect(stringId == .string("request-1"))

    let integerData = try encoder.encode(AppServerModels.ID.integer(42))
    let integerId = try decoder.decode(AppServerModels.ID.self, from: integerData)
    #expect(String(data: integerData, encoding: .utf8) == "42")
    #expect(integerId == .integer(42))
}

@Test func threadListCwdFilterSupportsSwitchingOnCustomType() async throws {
    let filter = Components.Schemas.ThreadListCwdFilter.paths(["/tmp", "/var/tmp"])

    switch filter {
    case .path:
        Issue.record("Expected a paths filter")
    case let .paths(paths):
        #expect(paths == ["/tmp", "/var/tmp"])
    }
}

@Test func functionCallOutputBodyRoundTripsText() async throws {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    let data = try encoder.encode(Components.Schemas.FunctionCallOutputBody.text("done"))
    let body = try decoder.decode(Components.Schemas.FunctionCallOutputBody.self, from: data)

    #expect(String(data: data, encoding: .utf8) == "\"done\"")
    #expect(body == .text("done"))
}

@Test func fileUploaderCopiesDataAndReportsProgress() async throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let uploader = AppServerFileUploader(
        destinationDirectory: root.appendingPathComponent("Attachments"),
        referenceRoot: root
    )
    let payload = Data(repeating: 0x5A, count: 1_200_000)

    var states: [AppServerFileUploadState] = []
    for try await state in uploader.uploadData(
        payload,
        fileName: "sample.bin",
        kind: .file,
        mediaType: "application/octet-stream"
    ) {
        states.append(state)
    }

    #expect(states.first == .waiting)
    let completed = states.compactMap { state -> AppServerUploadedFile? in
        guard case let .completed(file) = state else { return nil }
        return file
    }.first
    #expect(completed?.byteCount == Int64(payload.count))
    #expect(completed?.referencePath.hasPrefix("Attachments/") == true)
    #expect(try Data(contentsOf: completed!.url) == payload)
    #expect(states.contains { state in
        guard case let .uploading(copied, total) = state else { return false }
        return copied == total && total == Int64(payload.count)
    })
}

@Test func fileUploaderRejectsOversizedPayload() async throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let uploader = AppServerFileUploader(
        destinationDirectory: root,
        maximumByteCount: 3
    )

    await #expect(throws: AppServerFileUploadError.fileTooLarge(limitBytes: 3, actualBytes: 4)) {
        for try await _ in uploader.uploadData(Data([1, 2, 3, 4]), fileName: "large.bin") {}
    }
}

@Test func fileUploaderCopiesSelectedFile() async throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let source = root.appendingPathComponent("source.txt")
    try Data("hello from a selected file".utf8).write(to: source)
    let uploader = AppServerFileUploader(
        destinationDirectory: root.appendingPathComponent("Uploads"),
        referenceRoot: root
    )

    var completed: AppServerUploadedFile?
    for try await state in uploader.uploadFile(at: source, mediaType: "text/plain") {
        if case let .completed(file) = state {
            completed = file
        }
    }

    #expect(completed?.originalName == "source.txt")
    #expect(completed?.kind == .file)
    #expect(completed?.referencePath.hasPrefix("Uploads/") == true)
    #expect(try String(contentsOf: completed!.url, encoding: .utf8) == "hello from a selected file")
}

@Test func turnInputBuilderUsesTypedImagesAndWorkspaceFileReferences() async throws {
    let root = URL(fileURLWithPath: "/workspace")
    let image = AppServerUploadedFile(
        id: UUID(),
        originalName: "photo.jpg",
        url: root.appendingPathComponent("Attachments/photo.jpg"),
        referencePath: "Attachments/photo.jpg",
        byteCount: 12,
        mediaType: "image/jpeg",
        kind: .image
    )
    let document = AppServerUploadedFile(
        id: UUID(),
        originalName: "notes.txt",
        url: root.appendingPathComponent("Attachments/notes.txt"),
        referencePath: "Attachments/notes.txt",
        byteCount: 8,
        mediaType: "text/plain",
        kind: .file
    )

    let input = AppServerTurnInputBuilder.make(
        text: "Summarize these",
        attachments: [image, document]
    )

    #expect(input.count == 2)
    guard case let .text(text) = input[0] else {
        Issue.record("Expected text input")
        return
    }
    #expect(text.text.contains("Attachments/notes.txt"))
    guard case let .localImage(localImage) = input[1] else {
        Issue.record("Expected local image input")
        return
    }
    #expect(localImage.path == "/workspace/Attachments/photo.jpg")
}

@Test func clientRequestPropagatesTransportWriteFailure() async throws {
    let connection = TestConnection(writeFailure: TestTransportError.writeFailed)
    let client = AppServerClient(connection: connection)

    await #expect(throws: TestTransportError.writeFailed) {
        _ = try await client.send(
            request: AppServerModels.ClientRequest.ThreadList.self,
            with: .init(limit: 1)
        )
    }
}

@Test func closingConnectionFailsPendingClientRequests() async throws {
    let connection = TestConnection(finishAfterWrite: true)
    let client = AppServerClient(connection: connection)
    let eventTask = Task {
        await client.handleEvents(logMessages: false)
    }

    await #expect(throws: AppServerClientError.connectionClosed) {
        _ = try await client.send(
            request: AppServerModels.ClientRequest.ThreadList.self,
            with: .init(limit: 1)
        )
    }
    await eventTask.value
}

private enum TestTransportError: Error, Equatable {
    case writeFailed
}

private actor TestConnection: AppServerConnection {
    nonisolated let reader: AsyncStream<Data>

    private let continuation: AsyncStream<Data>.Continuation
    private let writeFailure: TestTransportError?
    private let finishAfterWrite: Bool

    init(
        writeFailure: TestTransportError? = nil,
        finishAfterWrite: Bool = false
    ) {
        let stream = AsyncStream<Data>.makeStream(bufferingPolicy: .unbounded)
        reader = stream.stream
        continuation = stream.continuation
        self.writeFailure = writeFailure
        self.finishAfterWrite = finishAfterWrite
    }

    func write(_ data: Data) async throws {
        if let writeFailure {
            throw writeFailure
        }
        if finishAfterWrite {
            continuation.finish()
        }
    }
}
