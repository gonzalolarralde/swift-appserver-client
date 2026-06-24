public enum ForcedChatgptWorkspaceIdsValue: Codable, Hashable, Sendable {
    case workspace(String)
    case workspaces([String])

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .workspace(value)
            return
        }
        if let value = try? container.decode([String].self) {
            self = .workspaces(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("ForcedChatgptWorkspaceIds")
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .workspace(value):
            try container.encode(value)
        case let .workspaces(value):
            try container.encode(value)
        }
    }
}
