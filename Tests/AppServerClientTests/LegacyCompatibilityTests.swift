import Foundation
import Testing
@testable import AppServerClient

@Test func removedRollbackFailsBeforeWritingOrAllocatingRequestID() async throws {
    let connection = LegacyRecordingConnection()
    let client = AppServerClient(connection: connection)

    await #expect(throws: AppServerClientError.unsupportedMethod("thread/rollback")) {
        _ = try await client.send(
            request: AppServerModels.ClientRequest.ThreadRollback.self,
            with: .init(numTurns: 1, threadId: "thread-1")
        )
    }
    #expect(await connection.writes.isEmpty)
    #expect(await client.nextRequestID == 1)
}

@Test func legacyRollbackStillRoundTripsAsARequestModel() throws {
    let request = AppServerModels.ClientRequest.ThreadRollback.build(
        id: .integer(4), params: .init(numTurns: 2, threadId: "thread-1")
    )
    #expect(try JSONDecoder().decode(AppServerModels.ClientRequest.self, from: JSONEncoder().encode(request)) == request)
}

@Test func removedPluginModelsRoundTripHistoricalData() throws {
    let data = Data(#"{"entrypoints":[{"appId":"app","icons":[{"src":"icon.svg"}],"quickAction":{"icons":[],"target":{"name":"open","type":"tool","arguments":{"path":"a"}},"title":"Open"},"resourceUri":"ui://main","title":"Main","toolName":"main","type":"global"},{"appId":"app","icons":[],"resourceUri":"ui://settings","searchTerms":["config"],"title":"Settings","toolName":"settings","type":"settings"},{"appId":"app","icons":[],"resourceUri":"ui://thread","title":"Thread","toolName":"thread","type":"thread"},{"appId":"app","extensions":["txt"],"icons":[],"resourceUri":"ui://file","title":"File","toolName":"file","type":"file"}],"fileHandlers":[],"searchMentionProviders":[{"appId":"app","call":{"_meta":{},"arguments":{"q":"test"},"name":"search"},"linkId":"link","title":"Search","toolName":"search"}],"settings":[{"appId":"app","readToolName":"read","updateToolName":"update"}],"settingsEntrypoints":[],"threadEntrypoints":[]}"#.utf8)
    let model = try JSONDecoder().decode(Components.Schemas.PluginExtensions.self, from: data)
    let expected = try #require(JSONSerialization.jsonObject(with: data) as? NSDictionary)
    let actual = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(model)) as? NSDictionary)
    #expect(actual == expected)
}

@Test func removedWindowsFieldIsOptionalAndPreservesHistoricalValues() throws {
    let decoder = JSONDecoder()
    let current = try decoder.decode(Components.Schemas.ConfigRequirements.self, from: Data("{}".utf8))
    #expect(current.windowsSandboxPrivateDesktop == nil)
    let legacy = try decoder.decode(Components.Schemas.ConfigRequirements.self, from: Data(#"{"windowsSandboxPrivateDesktop":true}"#.utf8))
    #expect(legacy.windowsSandboxPrivateDesktop == true)
    #expect(try decoder.decode(Components.Schemas.ConfigRequirements.self, from: JSONEncoder().encode(legacy)) == legacy)
}

@Test func removedPluginSummaryFieldIsOptionalAndPreservesHistoricalValues() throws {
    let decoder = JSONDecoder()
    let data = Data(#"{"authPolicy":"ON_INSTALL","enabled":true,"id":"plugin","installPolicy":"AVAILABLE","installed":true,"name":"Plugin","source":{"path":"/tmp/plugin","type":"local"}}"#.utf8)
    var summary = try decoder.decode(Components.Schemas.PluginSummary.self, from: data)
    #expect(summary.extensions == nil)
    summary.extensions = .init(settings: [.init(appId: "app", readToolName: "read", updateToolName: "update")])
    #expect(try decoder.decode(Components.Schemas.PluginSummary.self, from: JSONEncoder().encode(summary)) == summary)
}

private actor LegacyRecordingConnection: AppServerConnection {
    nonisolated let reader = AsyncStream<Data> { $0.finish() }
    private(set) var writes: [Data] = []

    func write(_ data: Data) async throws {
        writes.append(data)
    }
}
