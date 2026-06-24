public enum McpElicitationSingleSelectEnumSchemaValue: Codable, Hashable, Sendable {
    case untitled(Components.Schemas.McpElicitationUntitledSingleSelectEnumSchema)
    case titled(Components.Schemas.McpElicitationTitledSingleSelectEnumSchema)

    public init(from decoder: any Decoder) throws {
        if let value = try? Components.Schemas.McpElicitationUntitledSingleSelectEnumSchema(from: decoder) {
            self = .untitled(value)
            return
        }
        if let value = try? Components.Schemas.McpElicitationTitledSingleSelectEnumSchema(from: decoder) {
            self = .titled(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("McpElicitationSingleSelectEnumSchema")
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .untitled(value):
            try value.encode(to: encoder)
        case let .titled(value):
            try value.encode(to: encoder)
        }
    }
}

public enum McpElicitationMultiSelectEnumSchemaValue: Codable, Hashable, Sendable {
    case untitled(Components.Schemas.McpElicitationUntitledMultiSelectEnumSchema)
    case titled(Components.Schemas.McpElicitationTitledMultiSelectEnumSchema)

    public init(from decoder: any Decoder) throws {
        if let value = try? Components.Schemas.McpElicitationUntitledMultiSelectEnumSchema(from: decoder) {
            self = .untitled(value)
            return
        }
        if let value = try? Components.Schemas.McpElicitationTitledMultiSelectEnumSchema(from: decoder) {
            self = .titled(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("McpElicitationMultiSelectEnumSchema")
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .untitled(value):
            try value.encode(to: encoder)
        case let .titled(value):
            try value.encode(to: encoder)
        }
    }
}

public enum McpElicitationEnumSchemaValue: Codable, Hashable, Sendable {
    case singleSelect(Components.Schemas.McpElicitationSingleSelectEnumSchema)
    case multiSelect(Components.Schemas.McpElicitationMultiSelectEnumSchema)
    case legacyTitled(Components.Schemas.McpElicitationLegacyTitledEnumSchema)

    public init(from decoder: any Decoder) throws {
        if let value = try? Components.Schemas.McpElicitationSingleSelectEnumSchema(from: decoder) {
            self = .singleSelect(value)
            return
        }
        if let value = try? Components.Schemas.McpElicitationMultiSelectEnumSchema(from: decoder) {
            self = .multiSelect(value)
            return
        }
        if let value = try? Components.Schemas.McpElicitationLegacyTitledEnumSchema(from: decoder) {
            self = .legacyTitled(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("McpElicitationEnumSchema")
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .singleSelect(value):
            try value.encode(to: encoder)
        case let .multiSelect(value):
            try value.encode(to: encoder)
        case let .legacyTitled(value):
            try value.encode(to: encoder)
        }
    }
}

public enum McpElicitationPrimitiveSchemaValue: Codable, Hashable, Sendable {
    case `enum`(Components.Schemas.McpElicitationEnumSchema)
    case string(Components.Schemas.McpElicitationStringSchema)
    case number(Components.Schemas.McpElicitationNumberSchema)
    case boolean(Components.Schemas.McpElicitationBooleanSchema)

    public init(from decoder: any Decoder) throws {
        if let value = try? Components.Schemas.McpElicitationEnumSchema(from: decoder) {
            self = .enum(value)
            return
        }
        if let value = try? Components.Schemas.McpElicitationStringSchema(from: decoder) {
            self = .string(value)
            return
        }
        if let value = try? Components.Schemas.McpElicitationNumberSchema(from: decoder) {
            self = .number(value)
            return
        }
        if let value = try? Components.Schemas.McpElicitationBooleanSchema(from: decoder) {
            self = .boolean(value)
            return
        }
        throw AnyOfValueError.noMatchingValue("McpElicitationPrimitiveSchema")
    }

    public func encode(to encoder: any Encoder) throws {
        switch self {
        case let .enum(value):
            try value.encode(to: encoder)
        case let .string(value):
            try value.encode(to: encoder)
        case let .number(value):
            try value.encode(to: encoder)
        case let .boolean(value):
            try value.encode(to: encoder)
        }
    }
}
