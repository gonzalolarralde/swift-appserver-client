import Foundation

/// Preserves the audio discriminator and either inline/URL audio or a file reference.
public struct AudioUserInputValue: Codable, Hashable, Sendable {
    public enum _TypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case audio
    }
    public var url: String?
    public var fileId: String?
    public var _type: _TypePayload
    public init(url: String? = nil, fileId: String? = nil, _type: _TypePayload) {
        self.url = url
        self.fileId = fileId
        self._type = _type
    }
    /// Retains the pre-file-reference initializer's argument order.
    public init(_type: _TypePayload, url: String) {
        self.init(url: url, _type: _type)
    }
    public enum CodingKeys: String, CodingKey {
        case url = "url"
        case fileId = "fileId"
        case _type = "type"
    }
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId)
        _type = try container.decode(_TypePayload.self, forKey: ._type)
        guard url != nil || fileId != nil else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Audio requires url or fileId"))
        }
    }
    public func encode(to encoder: any Encoder) throws {
        guard url != nil || fileId != nil else {
            throw EncodingError.invalidValue(self, .init(codingPath: encoder.codingPath, debugDescription: "Audio requires url or fileId"))
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(fileId, forKey: .fileId)
        try container.encode(_type, forKey: ._type)
    }
}

/// Preserves the audio discriminator and either inline/URL audio or a file reference.
public struct InputAudioContentItemValue: Codable, Hashable, Sendable {
    public enum _TypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case inputAudio = "input_audio"
    }
    public var audioUrl: String?
    public var fileId: String?
    public var _type: _TypePayload
    public init(audioUrl: String? = nil, fileId: String? = nil, _type: _TypePayload) {
        self.audioUrl = audioUrl
        self.fileId = fileId
        self._type = _type
    }
    public enum CodingKeys: String, CodingKey {
        case audioUrl = "audio_url"
        case fileId = "file_id"
        case _type = "type"
    }
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId)
        _type = try container.decode(_TypePayload.self, forKey: ._type)
        guard audioUrl != nil || fileId != nil else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Audio requires audio_url or file_id"))
        }
    }
    public func encode(to encoder: any Encoder) throws {
        guard audioUrl != nil || fileId != nil else {
            throw EncodingError.invalidValue(self, .init(codingPath: encoder.codingPath, debugDescription: "Audio requires audio_url or file_id"))
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(audioUrl, forKey: .audioUrl)
        try container.encodeIfPresent(fileId, forKey: .fileId)
        try container.encode(_type, forKey: ._type)
    }
}
