import OpenAPIRuntime

private struct ErrorInfoKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

private func requireOnlyErrorKey(_ decoder: any Decoder, key: String) throws {
    let container = try decoder.container(keyedBy: ErrorInfoKey.self)
    guard container.allKeys.map(\.stringValue) == [key] else {
        throw DecodingError.dataCorrupted(.init(
            codingPath: decoder.codingPath,
            debugDescription: "Additional error fields require lossless unknown decoding"
        ))
    }
}

/// Known server error cases retain their pre-0.161 Swift names and payload types.
/// Unknown string/object errors round-trip without discarding server details.
public enum CodexErrorInfoValue: Codable, Hashable, Sendable {
    public enum Case1Payload: String, Codable, Hashable, Sendable, CaseIterable {
        case contextWindowExceeded
        case sessionBudgetExceeded
        case usageLimitExceeded
        case rateLimitExceeded
        case flexUnavailable
        case serverOverloaded
        case cyberPolicy
        case misalignmentPolicyViolation
        case tooManyDenials
        case internalServerError
        case unauthorized
        case badRequest
        case threadRollbackFailed
        case sandboxError
        case other
    }

    public struct HTTPStatusPayload: Codable, Hashable, Sendable {
        public var httpStatusCode: Int?
        public init(httpStatusCode: Int? = nil) { self.httpStatusCode = httpStatusCode }
        public enum CodingKeys: String, CodingKey { case httpStatusCode }
    }

    public struct Case2Payload: Codable, Hashable, Sendable {
        public typealias HttpConnectionFailedPayload = HTTPStatusPayload
        public var httpConnectionFailed: HttpConnectionFailedPayload
        public init(httpConnectionFailed: HttpConnectionFailedPayload) { self.httpConnectionFailed = httpConnectionFailed }
        public enum CodingKeys: String, CodingKey { case httpConnectionFailed }
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.httpConnectionFailed = try container.decode(HttpConnectionFailedPayload.self, forKey: .httpConnectionFailed)
            try requireOnlyErrorKey(decoder, key: "httpConnectionFailed")
        }
    }

    public struct Case3Payload: Codable, Hashable, Sendable {
        public typealias ResponseStreamConnectionFailedPayload = HTTPStatusPayload
        public var responseStreamConnectionFailed: ResponseStreamConnectionFailedPayload
        public init(responseStreamConnectionFailed: ResponseStreamConnectionFailedPayload) { self.responseStreamConnectionFailed = responseStreamConnectionFailed }
        public enum CodingKeys: String, CodingKey { case responseStreamConnectionFailed }
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.responseStreamConnectionFailed = try container.decode(ResponseStreamConnectionFailedPayload.self, forKey: .responseStreamConnectionFailed)
            try requireOnlyErrorKey(decoder, key: "responseStreamConnectionFailed")
        }
    }

    public struct Case4Payload: Codable, Hashable, Sendable {
        public typealias ResponseStreamDisconnectedPayload = HTTPStatusPayload
        public var responseStreamDisconnected: ResponseStreamDisconnectedPayload
        public init(responseStreamDisconnected: ResponseStreamDisconnectedPayload) { self.responseStreamDisconnected = responseStreamDisconnected }
        public enum CodingKeys: String, CodingKey { case responseStreamDisconnected }
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.responseStreamDisconnected = try container.decode(ResponseStreamDisconnectedPayload.self, forKey: .responseStreamDisconnected)
            try requireOnlyErrorKey(decoder, key: "responseStreamDisconnected")
        }
    }

    public struct Case5Payload: Codable, Hashable, Sendable {
        public typealias ResponseTooManyFailedAttemptsPayload = HTTPStatusPayload
        public var responseTooManyFailedAttempts: ResponseTooManyFailedAttemptsPayload
        public init(responseTooManyFailedAttempts: ResponseTooManyFailedAttemptsPayload) { self.responseTooManyFailedAttempts = responseTooManyFailedAttempts }
        public enum CodingKeys: String, CodingKey { case responseTooManyFailedAttempts }
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.responseTooManyFailedAttempts = try container.decode(ResponseTooManyFailedAttemptsPayload.self, forKey: .responseTooManyFailedAttempts)
            try requireOnlyErrorKey(decoder, key: "responseTooManyFailedAttempts")
        }
    }

    public struct Case6Payload: Codable, Hashable, Sendable {
        public struct ActiveTurnNotSteerablePayload: Codable, Hashable, Sendable {
            public var turnKind: Components.Schemas.NonSteerableTurnKind
            public init(turnKind: Components.Schemas.NonSteerableTurnKind) { self.turnKind = turnKind }
            public enum CodingKeys: String, CodingKey { case turnKind }
        }
        public var activeTurnNotSteerable: ActiveTurnNotSteerablePayload
        public init(activeTurnNotSteerable: ActiveTurnNotSteerablePayload) { self.activeTurnNotSteerable = activeTurnNotSteerable }
        public enum CodingKeys: String, CodingKey { case activeTurnNotSteerable }
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.activeTurnNotSteerable = try container.decode(ActiveTurnNotSteerablePayload.self, forKey: .activeTurnNotSteerable)
            try requireOnlyErrorKey(decoder, key: "activeTurnNotSteerable")
        }
    }

    case case1(Case1Payload)
    case case2(Case2Payload)
    case case3(Case3Payload)
    case case4(Case4Payload)
    case case5(Case5Payload)
    case case6(Case6Payload)
    case unknown(OpenAPIValueContainer)

    public init(from decoder: any Decoder) throws {
        if let value = try? Case1Payload(from: decoder) {
            self = .case1(value)
            return
        }
        if let value = try? Case2Payload(from: decoder) {
            self = .case2(value)
            return
        }
        if let value = try? Case3Payload(from: decoder) {
            self = .case3(value)
            return
        }
        if let value = try? Case4Payload(from: decoder) {
            self = .case4(value)
            return
        }
        if let value = try? Case5Payload(from: decoder) {
            self = .case5(value)
            return
        }
        if let value = try? Case6Payload(from: decoder) {
            self = .case6(value)
            return
        }
        let value = try OpenAPIValueContainer(from: decoder)
        guard value.value is String || value.value is [String: (any Sendable)?] else {
            throw DecodingError.typeMismatch(Self.self, .init(
                codingPath: decoder.codingPath,
                debugDescription: "Codex errors must be strings or objects"
            ))
        }
        self = .unknown(value)
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .case1(value): try value.encode(to: encoder)
        case let .case2(value): try value.encode(to: encoder)
        case let .case3(value): try value.encode(to: encoder)
        case let .case4(value): try value.encode(to: encoder)
        case let .case5(value): try value.encode(to: encoder)
        case let .case6(value): try value.encode(to: encoder)
        case let .unknown(value): try value.encode(to: encoder)
        }
    }
}
