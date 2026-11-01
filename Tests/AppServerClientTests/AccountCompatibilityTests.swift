import Foundation
import Testing
@testable import AppServerClient

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
