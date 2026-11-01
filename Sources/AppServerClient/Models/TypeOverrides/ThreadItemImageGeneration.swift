import Foundation

/// Preserves common image-generation fields alongside inline data or a file ID.
/// At least one output representation must be present; both are retained when sent.
public struct ThreadItemImageGenerationValue: Codable, Hashable, Sendable {
    public enum _TypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case imageGeneration
    }

    public var completedAtMs: Int64?
    public var failure: Components.Schemas.ImageGenerationFailure?
    public var fileId: String?
    public var generationId: String?
    public var id: String
    public var inputImages: [Components.Schemas.ImageGenerationInputImage]?
    public var result: String?
    public var revisedPrompt: String?
    public var savedPath: Components.Schemas.AbsolutePathBuf?
    public var startedAtMs: Int64?
    public var status: String
    public var transparentBackground: Bool?
    public var _type: _TypePayload

    public init(
        completedAtMs: Int64? = nil,
        failure: Components.Schemas.ImageGenerationFailure? = nil,
        fileId: String? = nil,
        generationId: String? = nil,
        id: String,
        inputImages: [Components.Schemas.ImageGenerationInputImage]? = nil,
        result: String? = nil,
        revisedPrompt: String? = nil,
        savedPath: Components.Schemas.AbsolutePathBuf? = nil,
        startedAtMs: Int64? = nil,
        status: String,
        transparentBackground: Bool? = nil,
        _type: _TypePayload
    ) {
        self.completedAtMs = completedAtMs
        self.failure = failure
        self.fileId = fileId
        self.generationId = generationId
        self.id = id
        self.inputImages = inputImages
        self.result = result
        self.revisedPrompt = revisedPrompt
        self.savedPath = savedPath
        self.startedAtMs = startedAtMs
        self.status = status
        self.transparentBackground = transparentBackground
        self._type = _type
    }

    public enum CodingKeys: String, CodingKey {
        case completedAtMs, failure, fileId, generationId, id, inputImages
        case result, revisedPrompt, savedPath, startedAtMs, status, transparentBackground
        case _type = "type"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completedAtMs = try container.decodeIfPresent(Int64.self, forKey: .completedAtMs)
        failure = try container.decodeIfPresent(Components.Schemas.ImageGenerationFailure.self, forKey: .failure)
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId)
        generationId = try container.decodeIfPresent(String.self, forKey: .generationId)
        id = try container.decode(String.self, forKey: .id)
        inputImages = try container.decodeIfPresent([Components.Schemas.ImageGenerationInputImage].self, forKey: .inputImages)
        result = try container.decodeIfPresent(String.self, forKey: .result)
        revisedPrompt = try container.decodeIfPresent(String.self, forKey: .revisedPrompt)
        savedPath = try container.decodeIfPresent(Components.Schemas.AbsolutePathBuf.self, forKey: .savedPath)
        startedAtMs = try container.decodeIfPresent(Int64.self, forKey: .startedAtMs)
        status = try container.decode(String.self, forKey: .status)
        transparentBackground = try container.decodeIfPresent(Bool.self, forKey: .transparentBackground)
        _type = try container.decode(_TypePayload.self, forKey: ._type)
        guard fileId != nil || result != nil else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Image generation requires fileId or result"
            ))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        guard fileId != nil || result != nil else {
            throw EncodingError.invalidValue(self, .init(
                codingPath: encoder.codingPath,
                debugDescription: "Image generation requires fileId or result"
            ))
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(completedAtMs, forKey: .completedAtMs)
        try container.encodeIfPresent(failure, forKey: .failure)
        try container.encodeIfPresent(fileId, forKey: .fileId)
        try container.encodeIfPresent(generationId, forKey: .generationId)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(inputImages, forKey: .inputImages)
        try container.encodeIfPresent(result, forKey: .result)
        try container.encodeIfPresent(revisedPrompt, forKey: .revisedPrompt)
        try container.encodeIfPresent(savedPath, forKey: .savedPath)
        try container.encodeIfPresent(startedAtMs, forKey: .startedAtMs)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(transparentBackground, forKey: .transparentBackground)
        try container.encode(_type, forKey: ._type)
    }
}
