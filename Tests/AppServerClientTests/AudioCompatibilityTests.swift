import Foundation
import Testing
@testable import AppServerClient

@Test func audioUserInputsPreserveBothRepresentationsAndDiscriminator() throws {
    for payload in [
        #"{"type":"audio","url":"data:audio/wav;base64,YQ=="}"#,
        #"{"type":"audio","fileId":"file-audio"}"#,
        #"{"type":"audio","url":"data:audio/wav;base64,YQ==","fileId":"file-audio"}"#
    ] {
        let original = Data(payload.utf8)
        let value = try JSONDecoder().decode(Components.Schemas.UserInput.self, from: original)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONSerialization.jsonObject(with: original) as? NSDictionary == JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
    }
}

@Test func inputAudioContentPreservesBothRepresentationsAndDiscriminator() throws {
    for payload in [
        #"{"type":"input_audio","audio_url":"data:audio/wav;base64,YQ=="}"#,
        #"{"type":"input_audio","file_id":"file-audio"}"#,
        #"{"type":"input_audio","audio_url":"data:audio/wav;base64,YQ==","file_id":"file-audio"}"#
    ] {
        let original = Data(payload.utf8)
        let value = try JSONDecoder().decode(Components.Schemas.ContentItem.self, from: original)
        let encoded = try JSONEncoder().encode(value)
        #expect(try JSONSerialization.jsonObject(with: original) as? NSDictionary == JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
    }
}

@Test func audioReferencesRequireAtLeastOneRepresentation() throws {
    #expect(throws: (any Error).self) { try JSONDecoder().decode(AudioUserInputValue.self, from: Data(#"{"type":"audio"}"#.utf8)) }
    #expect(throws: (any Error).self) { try JSONDecoder().decode(InputAudioContentItemValue.self, from: Data(#"{"type":"input_audio"}"#.utf8)) }
    #expect(throws: (any Error).self) { try JSONEncoder().encode(AudioUserInputValue(_type: .audio)) }
    #expect(throws: (any Error).self) { try JSONEncoder().encode(InputAudioContentItemValue(_type: .inputAudio)) }
}

@Test func historicalAudioConstructorsRetainWireShape() throws {
    let url = "data:audio/wav;base64,YQ=="
    let user = AudioUserInputValue(_type: .audio, url: url)
    let content = InputAudioContentItemValue(audioUrl: url, _type: .inputAudio)
    #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(user)) as? NSDictionary == ["type": "audio", "url": url] as NSDictionary)
    #expect(try JSONSerialization.jsonObject(with: JSONEncoder().encode(content)) as? NSDictionary == ["type": "input_audio", "audio_url": url] as NSDictionary)
}
