import Foundation

private struct InitializedNotification: Encodable {
    let method = "initialized"
}

public actor AppServerClient<Connection: AppServerConnection> {
    public typealias ServerNotificationHandler = @MainActor @Sendable (AppServerModels.ServerNotification) async -> Void
    public typealias ServerRequestHandler = @MainActor @Sendable (AppServerModels.ServerRequest) async -> Void

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
    private var serverNotificationHandler: ServerNotificationHandler?
    private var serverRequestHandler: ServerRequestHandler?
    var pendingClientRequests: [AppServerModels.ID: (Result<Data, Error>) -> Void] = [:]
    var nextRequestID: Int64 = 1

    public init(
        connection: Connection,
        onServerNotification: ServerNotificationHandler? = nil,
        onServerRequest: ServerRequestHandler? = nil
    ) {
        self.connection = connection
        self.serverNotificationHandler = onServerNotification
        self.serverRequestHandler = onServerRequest
    }

    public func setServerNotificationHandler(_ handler: ServerNotificationHandler?) {
        serverNotificationHandler = handler
    }

    public func setServerRequestHandler(_ handler: ServerRequestHandler?) {
        serverRequestHandler = handler
    }

    public func sendInitialize() async throws -> AppServerModels.ClientRequest.Initialize.Response {
        let response = try await send(
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
        try await sendInitialized()
        return response
    }

    public func sendInitialized() async throws {
        try await connection.write(JSONEncoder().encode(InitializedNotification()))
    }

    public func send<Requestable: ClientRequestable>(request: Requestable.Type, with params: Requestable.Params) async throws -> Requestable.Response {
        let decoder = JSONDecoder()

        let id = AppServerModels.ID.integer(nextRequestID)
        nextRequestID += 1

        return try await withCheckedThrowingContinuation { continuation in
            let request = Requestable.build(id: id, params: params)
            pendingClientRequests[id] = { response in
                switch response {
                case let .success(data):
                    do {
                        let callResult = try decoder.decode(CallResult<Requestable.Response>.self, from: data)
                        continuation.resume(returning: callResult.result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }

            Task {
                let encoded = try JSONEncoder().encode(request)
                try await self.connection.write(encoded)
            }
        }
    }

    public func respond<Requestable: ServerRequestable>(to request: Requestable, with response: Requestable.Response) async throws {
        try await connection.write(try request.build(response: response))
    }

    public func handleEvents(logMessages: Bool = true) async {
        let decoder = JSONDecoder()

        for await data in await connection.reader {
            if let response = try? decoder.decode(CallResult<VoidCodable>.self, from: data) {
                if let pendingRequest = pendingClientRequests.removeValue(forKey: response.id) {
                    pendingRequest(.success(data))
                } else if logMessages {
                    print("server-response: received reponse for unknown id \(response.id)")
                }
            } else if let response = try? decoder.decode(CallError.self, from: data) {
                if let pendingRequest = pendingClientRequests.removeValue(forKey: response.id) {
                    pendingRequest(.failure(response.error))
                } else if logMessages {
                    print("server-response: received reponse for unknown id \(response.id)")
                }
            } else if let request = try? decoder.decode(AppServerModels.ServerRequest.self, from: data) {
                await serverRequestHandler?(request)
                if logMessages {
                    print("server-request: \(request)")
                }
            } else if let notification = try? decoder.decode(AppServerModels.ServerNotification.self, from: data) {
                await serverNotificationHandler?(notification)
                if logMessages {
                    print("server-notification: \(notification)")
                }
            } else if let pretty = Self.prettyPrintedJSON(data) {
                if logMessages {
                    print("json: \(pretty)")
                }
            } else if logMessages {
                print("unparsed: \(String(data: data, encoding: .utf8) ?? "non readable data")")
            }
        }
    }
}
