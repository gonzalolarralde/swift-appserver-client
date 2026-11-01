import Foundation
import Testing
@testable import AppServerClient

@Test(arguments: [
    #""result":"aW1hZ2U=""#,
    #""fileId":"file-1""#,
    #""fileId":"file-1","result":"""#,
])
func imageGenerationPreservesOutputAndCommonFields(output: String) throws {
    let data = Data("""
        {"id":"image-1","status":"completed","type":"imageGeneration",
         "inputImages":[{"path":"/tmp/input.png","sha256":"digest"}],
         "revisedPrompt":"A test image","savedPath":"/tmp/output.png",
         "transparentBackground":true,\(output)}
        """.utf8)
    let item = try JSONDecoder().decode(Components.Schemas.ThreadItem.self, from: data)
    let actual = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(item)) as? NSDictionary)
    let expected = try #require(JSONSerialization.jsonObject(with: data) as? NSDictionary)
    #expect(actual == expected)
    #expect(try JSONDecoder().decode(Components.Schemas.ThreadItem.self, from: JSONEncoder().encode(item)) == item)
}

@Test func imageGenerationRequiresAnOutputRepresentation() throws {
    let data = Data(#"{"id":"image-1","status":"completed","type":"imageGeneration"}"#.utf8)
    #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(Components.Schemas.ThreadItem.self, from: data)
    }
    let item = ThreadItemImageGenerationValue(id: "image-1", status: "completed", _type: .imageGeneration)
    #expect(throws: EncodingError.self) { try JSONEncoder().encode(item) }
}
