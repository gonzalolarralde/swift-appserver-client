import Foundation
import Testing
@testable import AppServerClient

@Test(arguments: [
    #"{"type":"frame","channels":{"voice_transcript":{"role":"user","text":"Hello"}}}"#,
    #"{"type":"turnInputAccepted","handoff_id":"handoff-1","input":"Hello","input_item_id":"input-1","mode":"steer","source_event_ids":["event-1"],"turn_id":"turn-1"}"#,
    #"{"type":"sessionEndInputSaved","input":"Hello","input_item_id":"input-1","source_event_ids":["event-1"]}"#,
])
func realtimeHistoryRoundTripsNewItemsAndSharedObservationMetadata(_ payload: String) throws {
    let item = try #require(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
    var expected = item
    expected["id"] = "event-1"
    expected["realtimeSessionId"] = "session-1"
    expected["observedAtMs"] = Int64(1_795_186_654_321)
    let input = try JSONSerialization.data(withJSONObject: expected)
    let decoded = try JSONDecoder().decode(Components.Schemas.ThreadRealtimeItem.self, from: input)
    let encoded = try JSONEncoder().encode(decoded)
    let actual = try #require(JSONSerialization.jsonObject(with: encoded) as? NSDictionary)
    #expect(actual == expected as NSDictionary)
}
