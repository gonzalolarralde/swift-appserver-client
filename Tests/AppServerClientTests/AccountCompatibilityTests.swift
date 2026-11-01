import Foundation
import Testing
@testable import AppServerClient

@Test func accountSetupAndSessionRequestsUseTheirExportedResponses() throws {
    let setup: AppServerModels.ClientRequest.AccountGcpSetup.Response =
        try JSONDecoder().decode(Components.Schemas.GcpSetupResponse.self, from: Data("{}".utf8))
    #expect(try JSONDecoder().decode(Components.Schemas.GcpSetupResponse.self, from: JSONEncoder().encode(setup)) == setup)

    let sessions = Data(#"{"activeSessionId":"session-1","sessions":[]}"#.utf8)
    let list: AppServerModels.ClientRequest.AccountSessionList.Response =
        try JSONDecoder().decode(Components.Schemas.AccountSessionsResponse.self, from: sessions)
    #expect(list == .init(activeSessionId: "session-1", sessions: []))

    for data in [sessions, Data(#"{"auth_url":"https://example.test/login","login_id":"login-1"}"#.utf8)] {
        let switched: AppServerModels.ClientRequest.AccountSessionSwitch.Response =
            try JSONDecoder().decode(Components.Schemas.AccountSessionsSwitchResponse.self, from: data)
        let encoded = try JSONEncoder().encode(switched)
        #expect(try JSONSerialization.jsonObject(with: encoded) as? NSDictionary ==
            JSONSerialization.jsonObject(with: data) as? NSDictionary)
        #expect(try JSONDecoder().decode(Components.Schemas.AccountSessionsSwitchResponse.self, from: encoded) == switched)
    }
}

@Test func gcpAccountPreservesItsWireRepresentation() throws {
    let data = Data(#"{"type":"gcp"}"#.utf8)
    let account = try JSONDecoder().decode(Components.Schemas.Account.self, from: data)
    guard case .gcp = account else {
        Issue.record("Expected a Google Cloud account")
        return
    }
    #expect(try JSONDecoder().decode(Components.Schemas.Account.self, from: JSONEncoder().encode(account)) == account)
    #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(account)) as? NSDictionary ==
        JSONSerialization.jsonObject(with: data) as? NSDictionary)
}
