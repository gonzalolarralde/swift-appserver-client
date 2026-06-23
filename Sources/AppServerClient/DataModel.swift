import Foundation

struct CallResult<Response: Codable>: Codable {
    let id: Components.Schemas.RequestId
    let result: Response
}

public enum DataModelError: Error {
    case requestIdDoesntMatch
}

enum AppServerModels {
    typealias ID = Components.Schemas.RequestId
    typealias ClientRequest = Components.Schemas.ClientRequest
    typealias ServerRequest = Components.Schemas.ServerRequest
    typealias ServerNotification = Components.Schemas.ServerNotification
}

protocol ClientRequestable: Identifiable {
    associatedtype Params: Codable
    associatedtype Response: Codable & Sendable
    static func build(id: Components.Schemas.RequestId, params: Params) -> AppServerModels.ClientRequest
    var id: Components.Schemas.RequestId { get }
    var params: Params { get }
}

extension ClientRequestable {
    func parse(response: Data) throws -> Response {
        let decoder = JSONDecoder()
        let callResult = try decoder.decode(CallResult<Response>.self, from: response)
        guard callResult.id == self.id else {
            throw DataModelError.requestIdDoesntMatch
        }
        return callResult.result
    }
}

protocol ServerRequestable: Identifiable {
    associatedtype Params: Codable
    associatedtype Response: Codable
    static func build(id: Components.Schemas.RequestId, params: Params) -> AppServerModels.ServerRequest
    var id: Components.Schemas.RequestId { get }
    var params: Params { get }
}

extension ServerRequestable {
    func build(response: Response) throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(CallResult<Response>(id: self.id, result: response))
    }
}

protocol ServerNotificationPayload {
    associatedtype Params
    static func build(params: Params) -> AppServerModels.ServerNotification
    var params: Params { get }
}
