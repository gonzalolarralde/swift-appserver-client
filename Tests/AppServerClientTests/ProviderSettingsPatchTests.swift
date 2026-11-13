import Foundation
import Testing
@testable import AppServerClient

@Test func providerPatchPreservesOmittedNullAndStringSettings() throws {
    let payloads = [
        #"{"type":"customGateway","baseUrl":null,"name":"Gateway"}"#,
        #"{"type":"bedrock","providerId":"amazon-bedrock","profile":null,"region":"us-east-1"}"#,
        #"{"type":"gcp","providerId":"gcp","credentialFile":null,"projectId":"example"}"#
    ]
    for payload in payloads {
        let original = Data(payload.utf8)
        let patch = try JSONDecoder().decode(Components.Schemas.ProviderSettingsPatch.self, from: original)
        let encoded = try JSONEncoder().encode(patch)
        #expect(try JSONSerialization.jsonObject(with: original) as? NSDictionary == JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
    }
}

@Test func providerPatchCanExplicitlyClearASetting() throws {
    let patch = Components.Schemas.ProviderSettingsPatch.gcp(
        .init(credentialFile: .clear, projectId: .set("example"), providerId: .gcp)
    )
    let encoded = try JSONEncoder().encode(patch)
    let expected = ["type": "gcp", "providerId": "gcp", "credentialFile": NSNull(), "projectId": "example"] as NSDictionary
    #expect(try JSONSerialization.jsonObject(with: encoded) as? NSDictionary == expected)
}

@Test func providerPatchRejectsUnknownSettings() throws {
    let payload = Data(#"{"type":"gcp","providerId":"gcp","unexpected":true}"#.utf8)
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(Components.Schemas.ProviderSettingsPatch.self, from: payload)
    }
}
