import Foundation
import Testing
@testable import AppServerClient

@Test func govCloudRequestUsesTheExportedResponseType() throws {
    let response: AppServerModels.ClientRequest.AccountBedrockCheckGovCloudRequirements.Response =
        try JSONDecoder().decode(Components.Schemas.BedrockCheckGovCloudRequirementsResponse.self,
            from: Data(#"{"isGovCloud":true,"shouldWarn":true}"#.utf8))
    #expect(response == .init(isGovCloud: true, shouldWarn: true))
}

@Test func knownErrorCasesPreserveTheirSwiftAPIAndRoundTrip() throws {
    let values: [Components.Schemas.CodexErrorInfo] = [
        .case1(.rateLimitExceeded),
        .case2(.init(httpConnectionFailed: .init(httpStatusCode: 503))),
        .case3(.init(responseStreamConnectionFailed: .init())),
        .case4(.init(responseStreamDisconnected: .init(httpStatusCode: 429))),
        .case5(.init(responseTooManyFailedAttempts: .init())),
        .case6(.init(activeTurnNotSteerable: .init(turnKind: .review))),
    ]
    for value in values {
        #expect(try JSONDecoder().decode(Components.Schemas.CodexErrorInfo.self, from: JSONEncoder().encode(value)) == value)
    }
}

@Test func unknownErrorStringsAndObjectsArePreservedLosslessly() throws {
    for json in [#""futureServerError""#, #"{"futureError":{"reason":"new","attempt":2}}"#, #"{"httpConnectionFailed":{},"newMetadata":true}"#] {
        let original = Data(json.utf8)
        let value = try JSONDecoder().decode(Components.Schemas.CodexErrorInfo.self, from: original)
        guard case .unknown = value else {
            Issue.record("Expected an unknown error payload")
            continue
        }
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONSerialization.jsonObject(with: encoded, options: .fragmentsAllowed) as? NSObject == JSONSerialization.jsonObject(with: original, options: .fragmentsAllowed) as? NSObject)
    }
    for json in ["42", "null", "[]", "true"] {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Components.Schemas.CodexErrorInfo.self, from: Data(json.utf8))
        }
    }
}
