import Foundation

public protocol AppServerConnection: Actor {
    var reader: AsyncStream<Data> { get }
    func write(_ data: Data) async throws
}
