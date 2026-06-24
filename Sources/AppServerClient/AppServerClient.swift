import Foundation

public actor AppServerClient<Connection: AppServerConnection> {
    struct VoidCodable: Codable {
        init(from decoder: any Decoder) throws {}
    }

    private static func prettyPrintedJSON(_ data: Data) -> String? {
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            JSONSerialization.isValidJSONObject(object),
            let prettyData = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
            )
        else {
            return nil
        }
        return String(data: prettyData, encoding: .utf8)
    }

    private var connection: Connection
    var pendingClientRequests: [AppServerModels.ID: (Data) -> Void] = [:]
    var nextRequestID: Int64 = 1

    public init(connection: Connection) {
        self.connection = connection
    }

    public func sendInitialize() async throws -> AppServerModels.ClientRequest.Initialize.Response {
        try await send(
            request: AppServerModels.ClientRequest.Initialize.self,
            with: .init(
                capabilities: .init(experimentalApi: true),
                clientInfo: .init(
                    name: "swift-appserver-client",
                    title: "Swift AppServer Client",
                    version: "0.0.1"
                )
            )
        )
    }

    public func send<Requestable: ClientRequestable>(request: Requestable.Type, with params: Requestable.Params) async throws -> Requestable.Response {
        let decoder = JSONDecoder()

        let id = AppServerModels.ID.integer(nextRequestID)
        nextRequestID += 1

        return try await withCheckedThrowingContinuation { continuation in
            let request = Requestable.build(id: id, params: params)
            pendingClientRequests[id] = { response in
                do {
                    let callResult = try decoder.decode(CallResult<Requestable.Response>.self, from: response)
                    continuation.resume(returning: callResult.result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            Task {
                let encoded = try JSONEncoder().encode(request)
                try await self.connection.write(encoded)
            }
        }
    }

    public func handleEvents() async {
        let decoder = JSONDecoder()

        for await data in await connection.reader {
            if let response = try? decoder.decode(CallResult<VoidCodable>.self, from: data) {
                if let pendingRequest = pendingClientRequests.removeValue(forKey: response.id) {
                    pendingRequest(data)
                } else {
                    print("server-response: received reponse for unknown id \(response.id)")
                }
            } else if let request = try? decoder.decode(AppServerModels.ServerRequest.self, from: data) {
                print("server-request: \(request)")
            } else if let notification = try? decoder.decode(AppServerModels.ServerNotification.self, from: data) {
                print("server-notification: \(notification)")
            } else if let pretty = Self.prettyPrintedJSON(data) {
                print("json: \(pretty)")
            } else {
                print("unparsed: \(String(data: data, encoding: .utf8), default: "non readable data")")
            }
        }
    }
}
