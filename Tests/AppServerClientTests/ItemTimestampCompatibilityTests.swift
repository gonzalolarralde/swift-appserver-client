import Foundation
import Testing
@testable import AppServerClient

@Test(arguments: [
    #"{"id":"message-1","text":"hello","type":"agentMessage","startedAtMs":1700000000123,"completedAtMs":1700000000456}"#,
    #"{"id":"image-1","status":"completed","type":"imageGeneration","fileId":"file-1","generationId":"generation-1","startedAtMs":1700000000123,"completedAtMs":1700000000456}"#,
])
func itemTimestampsAndGenerationIDsSurviveRoundTrip(json: String) throws {
    let data = Data(json.utf8)
    let item = try JSONDecoder().decode(Components.Schemas.ThreadItem.self, from: data)
    let encoded = try JSONEncoder().encode(item)
    #expect(try JSONSerialization.jsonObject(with: encoded) as? NSDictionary ==
        JSONSerialization.jsonObject(with: data) as? NSDictionary)
    #expect(try JSONDecoder().decode(Components.Schemas.ThreadItem.self, from: encoded) == item)
}
