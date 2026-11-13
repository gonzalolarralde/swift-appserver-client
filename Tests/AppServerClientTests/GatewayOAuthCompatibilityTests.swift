import Foundation
import Testing
@testable import AppServerClient

@Test func gatewayOAuthRequestsSupportOmissionAndTypedParams() throws {
    let requests: [(AppServerModels.ClientRequest, String)] = [
        (AppServerModels.ClientRequest.AccountGatewayOAuthRead.build(id: .integer(1), params: nil),
         #"{"id":1,"method":"account/gatewayOAuth/read"}"#),
        (AppServerModels.ClientRequest.AccountGatewayOAuthRead.build(id: .integer(1), params: .init(modelProvider: "example")),
         #"{"id":1,"method":"account/gatewayOAuth/read","params":{"modelProvider":"example"}}"#),
        (AppServerModels.ClientRequest.AccountGatewayOAuthLogin.build(id: .integer(1), params: nil),
         #"{"id":1,"method":"account/gatewayOAuth/login"}"#),
        (AppServerModels.ClientRequest.AccountGatewayOAuthLogin.build(id: .integer(1), params: .init(deviceAuth: true, modelProvider: "example")),
         #"{"id":1,"method":"account/gatewayOAuth/login","params":{"deviceAuth":true,"modelProvider":"example"}}"#)
    ]
    for (request, expected) in requests {
        let encoded = try JSONEncoder().encode(request)
        #expect(try JSONSerialization.jsonObject(with: encoded) as? NSDictionary == JSONSerialization.jsonObject(with: Data(expected.utf8)) as? NSDictionary)
    }
}
