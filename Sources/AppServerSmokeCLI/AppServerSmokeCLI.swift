import AppServerClient

@main
struct Main {
    static func main() async throws {
        let connection = try StdIOAppServerConnection.connect()
        let client = AppServerClient(connection: connection)

        Task {
            await client.handleEvents()
        }

        let initResult = try await client.sendInitialize()
        print("Init response: \(initResult)")

        let account = try await client.send(request: AppServerModels.ClientRequest.AccountRead.self, with: .init())
        switch account.account {
        case .amazonBedrock: print("Amazon account")
        case .apiKey: print("API Key")
        case let .chatgpt(chatGPT): print("ChatGPT account: \(chatGPT.email)")
        case .none: print("No account detected")
        }

        let usage = try await client.send(request: AppServerModels.ClientRequest.AccountUsageRead.self, with: .init())
        print("Usage: \(usage.summary)")

        let threads = try await client.send(request: AppServerModels.ClientRequest.ThreadList.self, with: .init())

        for thread in threads.data {
            print("Thread: \(thread.name, default: "<Empty name>") \(thread.status.value1)) \(thread.cwd) \(String(describing: thread.agentNickname)) \(String(describing: thread.agentRole)) \(thread.source.value1)")
        }
    }
}
