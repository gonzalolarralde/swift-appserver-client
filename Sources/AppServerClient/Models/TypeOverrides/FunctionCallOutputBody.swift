public enum FunctionCallOutputBodyValue: Codable, Hashable, Sendable {
    case text(String)
    case contentItems([Components.Schemas.FunctionCallOutputContentItem])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .text(value)
            return
        }
        if let value = try? container.decode([Components.Schemas.FunctionCallOutputContentItem].self) {
            self = .contentItems(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("FunctionCallOutputBody")
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .text(value):
            try container.encode(value)
        case let .contentItems(value):
            try container.encode(value)
        }
    }
}
