/// A stable Swift representation of the app-server multi-agent mode wire value.
///
/// Codex 0.148.0 retains this value for compatibility but ignores it on thread
/// and turn requests. Ultra reasoning effort currently enables proactive mode.
public enum MultiAgentModeValue: Codable, Hashable, Sendable {
    /// Spawn subagents only when explicitly requested by applicable instructions.
    case explicitRequestOnly
    /// Permit proactive delegation when it materially improves the result.
    case proactive
    /// Supply custom delegation guidance on Codex versions that support it.
    case custom(String)

    private struct CustomPayload: Codable {
        let custom: String
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            switch value {
            case "explicitRequestOnly":
                self = .explicitRequestOnly
            case "proactive":
                self = .proactive
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown multi-agent mode: \(value)"
                )
            }
            return
        }

        self = .custom(try container.decode(CustomPayload.self).custom)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .explicitRequestOnly:
            try container.encode("explicitRequestOnly")
        case .proactive:
            try container.encode("proactive")
        case let .custom(value):
            try container.encode(CustomPayload(custom: value))
        }
    }
}
