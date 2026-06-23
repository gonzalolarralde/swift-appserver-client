import AppServerClient

@main
struct Main {
    static func main() async throws {
        let connection = try StdIOAppServerConnection.connect()
        try await AppServerClient(connection: connection).run()
    }
}
