import Foundation

private struct ProviderPatchKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

private func rejectUnknownSettings(_ decoder: any Decoder, knownKeys: Set<String>) throws {
    let container = try decoder.container(keyedBy: ProviderPatchKey.self)
    guard container.allKeys.allSatisfy({ knownKeys.contains($0.stringValue) }) else {
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown provider patch setting"))
    }
}

/// A provider setting patch distinguishes leaving a value alone from clearing it.
public enum ProviderSetting<Value: Codable & Hashable & Sendable>: Hashable, Sendable {
    case unchanged
    case clear
    case set(Value)
}

private extension KeyedDecodingContainer {
    func decodeProviderSetting<Value>(_ type: Value.Type, forKey key: Key) throws -> ProviderSetting<Value> {
        guard contains(key) else { return .unchanged }
        if try decodeNil(forKey: key) { return .clear }
        return .set(try decode(type, forKey: key))
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeProviderSetting<Value>(_ setting: ProviderSetting<Value>, forKey key: Key) throws {
        switch setting {
        case .unchanged: break
        case .clear: try encodeNil(forKey: key)
        case .set(let value): try encode(value, forKey: key)
        }
    }
}

public struct CustomGatewayProviderSettingsPatchValue: Codable, Hashable, Sendable {
    public enum _TypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case customGateway
    }

    public var baseUrl: ProviderSetting<String>
    public var envKey: ProviderSetting<String>
    public var name: ProviderSetting<String>
    public var providerId: ProviderSetting<String>
    public var _type: _TypePayload

    public init(
        baseUrl: ProviderSetting<String> = .unchanged,
        envKey: ProviderSetting<String> = .unchanged,
        name: ProviderSetting<String> = .unchanged,
        providerId: ProviderSetting<String> = .unchanged,
        _type: _TypePayload = .customGateway
    ) {
        self.baseUrl = baseUrl
        self.envKey = envKey
        self.name = name
        self.providerId = providerId
        self._type = _type
    }

    private enum CodingKeys: String, CodingKey {
        case baseUrl
        case envKey
        case name
        case providerId
        case _type = "type"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseUrl = try container.decodeProviderSetting(String.self, forKey: .baseUrl)
        envKey = try container.decodeProviderSetting(String.self, forKey: .envKey)
        name = try container.decodeProviderSetting(String.self, forKey: .name)
        providerId = try container.decodeProviderSetting(String.self, forKey: .providerId)
        _type = try container.decode(_TypePayload.self, forKey: ._type)
        try rejectUnknownSettings(decoder, knownKeys: ["baseUrl", "envKey", "name", "providerId", "type"])
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeProviderSetting(baseUrl, forKey: .baseUrl)
        try container.encodeProviderSetting(envKey, forKey: .envKey)
        try container.encodeProviderSetting(name, forKey: .name)
        try container.encodeProviderSetting(providerId, forKey: .providerId)
        try container.encode(_type, forKey: ._type)
    }
}

public struct BedrockProviderSettingsPatchValue: Codable, Hashable, Sendable {
    public enum _TypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case bedrock
    }

    public var profile: ProviderSetting<String>
    public var region: ProviderSetting<String>
    public var providerId: Components.Schemas.BedrockProviderId
    public var _type: _TypePayload

    public init(
        profile: ProviderSetting<String> = .unchanged,
        region: ProviderSetting<String> = .unchanged,
        providerId: Components.Schemas.BedrockProviderId,
        _type: _TypePayload = .bedrock
    ) {
        self.profile = profile
        self.region = region
        self.providerId = providerId
        self._type = _type
    }

    private enum CodingKeys: String, CodingKey {
        case profile
        case region
        case providerId
        case _type = "type"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeProviderSetting(String.self, forKey: .profile)
        region = try container.decodeProviderSetting(String.self, forKey: .region)
        providerId = try container.decode(Components.Schemas.BedrockProviderId.self, forKey: .providerId)
        _type = try container.decode(_TypePayload.self, forKey: ._type)
        try rejectUnknownSettings(decoder, knownKeys: ["profile", "region", "providerId", "type"])
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeProviderSetting(profile, forKey: .profile)
        try container.encodeProviderSetting(region, forKey: .region)
        try container.encode(providerId, forKey: .providerId)
        try container.encode(_type, forKey: ._type)
    }
}

public struct GcpProviderSettingsPatchValue: Codable, Hashable, Sendable {
    public enum _TypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case gcp
    }

    public var credentialFile: ProviderSetting<String>
    public var location: ProviderSetting<String>
    public var projectId: ProviderSetting<String>
    public var providerId: Components.Schemas.GcpProviderId
    public var _type: _TypePayload

    public init(
        credentialFile: ProviderSetting<String> = .unchanged,
        location: ProviderSetting<String> = .unchanged,
        projectId: ProviderSetting<String> = .unchanged,
        providerId: Components.Schemas.GcpProviderId,
        _type: _TypePayload = .gcp
    ) {
        self.credentialFile = credentialFile
        self.location = location
        self.projectId = projectId
        self.providerId = providerId
        self._type = _type
    }

    private enum CodingKeys: String, CodingKey {
        case credentialFile
        case location
        case projectId
        case providerId
        case _type = "type"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        credentialFile = try container.decodeProviderSetting(String.self, forKey: .credentialFile)
        location = try container.decodeProviderSetting(String.self, forKey: .location)
        projectId = try container.decodeProviderSetting(String.self, forKey: .projectId)
        providerId = try container.decode(Components.Schemas.GcpProviderId.self, forKey: .providerId)
        _type = try container.decode(_TypePayload.self, forKey: ._type)
        try rejectUnknownSettings(decoder, knownKeys: ["credentialFile", "location", "projectId", "providerId", "type"])
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeProviderSetting(credentialFile, forKey: .credentialFile)
        try container.encodeProviderSetting(location, forKey: .location)
        try container.encodeProviderSetting(projectId, forKey: .projectId)
        try container.encode(providerId, forKey: .providerId)
        try container.encode(_type, forKey: ._type)
    }
}
