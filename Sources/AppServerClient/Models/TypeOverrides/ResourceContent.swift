import OpenAPIRuntime

public enum ResourceContentValue: Codable, Hashable, Sendable {
    public struct Text: Codable, Hashable, Sendable {
        public var _meta: OpenAPIValueContainer?
        public var mimeType: String?
        public var text: String
        public var uri: String

        public init(
            _meta: OpenAPIValueContainer? = nil,
            mimeType: String? = nil,
            text: String,
            uri: String
        ) {
            self._meta = _meta
            self.mimeType = mimeType
            self.text = text
            self.uri = uri
        }
    }

    public struct Blob: Codable, Hashable, Sendable {
        public var _meta: OpenAPIValueContainer?
        public var blob: String
        public var mimeType: String?
        public var uri: String

        public init(
            _meta: OpenAPIValueContainer? = nil,
            blob: String,
            mimeType: String? = nil,
            uri: String
        ) {
            self._meta = _meta
            self.blob = blob
            self.mimeType = mimeType
            self.uri = uri
        }
    }

    case text(Text)
    case blob(Blob)

    public init(from decoder: any Decoder) throws {
        if let value = try? Text(from: decoder) {
            self = .text(value)
            return
        }
        if let value = try? Blob(from: decoder) {
            self = .blob(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("ResourceContent")
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .text(value):
            try value.encode(to: encoder)
        case let .blob(value):
            try value.encode(to: encoder)
        }
    }
}
