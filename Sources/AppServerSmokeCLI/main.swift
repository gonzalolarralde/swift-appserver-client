import AppServerClient
import Foundation

let exitCode: Int32
do {
    exitCode = try AppServerSmokeRunner().run()
} catch {
    FileHandle.standardError.write(Data("appserver-smoke: \(error)\n".utf8))
    exitCode = 1
}

Foundation.exit(exitCode)
