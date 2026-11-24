import Foundation
import Testing
@testable import AppServerClient

@Test(arguments: [
    #"{"type":"amazonBedrock","apiKey":"test-key","region":"us-east-1","providerId":"amazon-bedrock-runtime"}"#,
    #"{"type":"amazonBedrockAccessKeys","accessKeyId":"test-id","secretAccessKey":"test-secret","region":"us-east-1","providerId":"amazon-bedrock-runtime"}"#,
    #"{"type":"amazonBedrock","apiKey":"test-key","region":"us-east-1"}"#,
])
func bedrockLoginPreservesProviderSelectionAndLegacyOmission(_ json: String) throws {
    let data = Data(json.utf8)
    let value = try JSONDecoder().decode(Components.Schemas.LoginAccountParams.self, from: data)
    #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? NSDictionary ==
        JSONSerialization.jsonObject(with: data) as? NSDictionary)
}

@Test(arguments: [
    #"{"type":"profile","profile":"test-profile","region":"us-east-1","providerId":"amazon-bedrock-runtime"}"#,
    #"{"type":"environment","region":"us-east-1","providerId":"amazon-bedrock-runtime"}"#,
    #"{"type":"environment","region":"us-east-1"}"#,
])
func bedrockSetupPreservesProviderSelectionAndLegacyOmission(_ json: String) throws {
    let data = Data(json.utf8)
    let value = try JSONDecoder().decode(Components.Schemas.BedrockSetupParams.self, from: data)
    #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? NSDictionary ==
        JSONSerialization.jsonObject(with: data) as? NSDictionary)
}
