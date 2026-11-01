import Foundation

/// Preserves common image-generation fields alongside inline data or a file ID.
/// At least one output representation must be present; both are retained when sent.
public struct ThreadItemImageGenerationValue: Codable, Hashable, Sendable {
    public enum _TypePayload: String, Codable, Hashable, Sendable, CaseIterable {
        case imageGeneration
    }

    public var failure: Components.Schemas.ImageGenerationFailure?
    public var fileId: String?
    public var id: String
    public var inputImages: [Components.Schemas.ImageGenerationInputImage]?
    public var result: String?
    public var revisedPrompt: String?
    public var savedPath: Components.Schemas.AbsolutePathBuf?
    public var status: String
    public var transparentBackground: Bool?
    public var _type: _TypePayload

    public init(
        failure: Components.Schemas.ImageGenerationFailure? = nil,
        fileId: String? = nil,
        id: String,
        inputImages: [Components.Schemas.ImageGenerationInputImage]? = nil,
        result: String? = nil,
        revisedPrompt: String? = nil,
        savedPath: Components.Schemas.AbsolutePathBuf? = nil,
        status: String,
        transparentBackground: Bool? = nil,
        _type: _TypePayload
    ) {
        self.failure = failure
        self.fileId = fileId
        self.id = id
        self.inputImages = inputImages
        self.result = result
        self.revisedPrompt = revisedPrompt
        self.savedPath = savedPath
        self.status = status
        self.transparentBackground = transparentBackground
        self._type = _type
    }

    public enum CodingKeys: String, CodingKey {
        case failure, fileId, id, inputImages, result, revisedPrompt, savedPath
        case status, transparentBackground
        case _type = "type"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        failure = try container.decodeIfPresent(Components.Schemas.ImageGenerationFailure.self, forKey: .failure)
        fileId = try container.decodeIfPresent(String.self, forKey: .fileId)
        id = try container.decode(String.self, forKey: .id)
        inputImages = try container.decodeIfPresent([Components.Schemas.ImageGenerationInputImage].self, forKey: .inputImages)
        result = try container.decodeIfPresent(String.self, forKey: .result)
        revisedPrompt = try container.decodeIfPresent(String.self, forKey: .revisedPrompt)
        savedPath = try container.decodeIfPresent(Components.Schemas.AbsolutePathBuf.self, forKey: .savedPath)
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
        try container.encodeIfPresent(failure, forKey: .failure)
        try container.encodeIfPresent(fileId, forKey: .fileId)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(inputImages, forKey: .inputImages)
        try container.encodeIfPresent(result, forKey: .result)
        try container.encodeIfPresent(revisedPrompt, forKey: .revisedPrompt)
        try container.encodeIfPresent(savedPath, forKey: .savedPath)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(transparentBackground, forKey: .transparentBackground)
        try container.encode(_type, forKey: ._type)
    }
}
