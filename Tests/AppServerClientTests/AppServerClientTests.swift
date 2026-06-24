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
