public enum ThreadListCwdFilterValue: Codable, Hashable, Sendable {
    case path(String)
    case paths([String])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .path(value)
            return
        }
        if let value = try? container.decode([String].self) {
            self = .paths(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("ThreadListCwdFilter")
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .path(value):
            try container.encode(value)
        case let .paths(value):
            try container.encode(value)
        }
    }
}
