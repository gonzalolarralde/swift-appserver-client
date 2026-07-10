# Swift AppServer Client

Swift AppServer Client is a Swift package for talking to `codex app-server`.
It wraps the app-server JSON-RPC protocol with generated Swift models, typed
request/response mappings, and a simple stdio connection that launches
`codex app-server` as a child process.

The package currently focuses on model coverage and typed request plumbing. It
does not implement a high-level product API for every app-server feature yet.

## Package Contents

- `AppServerClient`: the library target.
- `appserver-smoke`: a small executable target that launches `codex app-server`,
  initializes the session, reads account information, and lists recent threads.
- `Scripts/generate-openapi.py`: regenerates the bundled OpenAPI document and
  Swift mapping helpers from the JSON schemas in `Sources/AppServerClient/JSONSchema`.

The generated Swift types come from `swift-openapi-generator`. A small set of
schema shapes that generate awkward Swift are overridden with hand-written
models under `Sources/AppServerClient/Models/TypeOverrides`.

## Requirements

- Swift 6.2 or newer.
- The `codex` CLI must be available on `PATH`.
- `codex app-server` must be supported by the installed Codex CLI.

## Building

```sh
swift build
```

To run the smoke executable:

```sh
swift run appserver-smoke
```

## Using From Another Swift Package

To depend on Swift AppServer Client from a SwiftPM package, add it to your
`Package.swift` dependencies:

```swift
dependencies: [
    .package(
        url: "https://github.com/gonzalolarralde/swift-appserver-client.git",
        branch: "main"
    ),
],
```

Then add the library product to the target that should use it:

```swift
targets: [
    .executableTarget(
        name: "MyTool",
        dependencies: [
            .product(
                name: "AppServerClient",
                package: "swift-appserver-client"
            ),
        ]
    ),
]
```

Once the package has version tags, prefer a version requirement instead:

```swift
dependencies: [
    .package(
        url: "https://github.com/gonzalolarralde/swift-appserver-client.git",
        from: "0.1.0"
    ),
],
```

## Basic Usage

Create a stdio connection, start the event loop, send `initialize`, and then
send typed client requests:

```swift
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
        print("Codex home:", initResult.codexHome)

        let account = try await client.send(
            request: AppServerModels.ClientRequest.AccountRead.self,
            with: .init()
        )

        switch account.account {
        case let .chatgpt(chatGPT):
            print("Signed in as:", chatGPT.email)
        case .apiKey:
            print("Using an API key account")
        case .amazonBedrock:
            print("Using Amazon Bedrock")
        case .none:
            print("No account detected")
        }
    }
}
```

`send(request:with:)` is generic over generated request types that conform to
`ClientRequestable`. The response type is inferred from the request mapping, so
this:

```swift
let threads = try await client.send(
    request: AppServerModels.ClientRequest.ThreadList.self,
    with: .init()
)
```

returns `AppServerModels.ClientRequest.ThreadList.Response`, which is currently
the generated `ThreadListResponse` model.

## Reading Threads

The smoke CLI shows the expected pattern for traversing thread data:

```swift
let threads = try await client.send(
    request: AppServerModels.ClientRequest.ThreadList.self,
    with: .init()
)

for thread in threads.data {
    print("Thread:", thread.name ?? "<Empty name>", thread.cwd)
}

if let firstThread = threads.data.first {
    let turns = try await client.send(
        request: AppServerModels.ClientRequest.ThreadTurnsList.self,
        with: .init(cursor: nil, itemsView: .full, threadId: firstThread.id)
    )

    for turn in turns.data {
        for item in turn.items {
            switch item {
            case let .agentMessage(message):
                print("Agent:", message.text)
            case let .userMessage(message):
                print("User:", message.content)
            case let .commandExecution(command):
                print("Command:", command.command)
            case let .mcpToolCall(toolCall):
                print("MCP tool:", toolCall.tool)
            default:
                print("Other item:", item)
            }
        }
    }
}
```

## Staging Attachments

The app-server accepts local image paths, while other local files are made
available to Codex through workspace paths. `AppServerFileUploader` copies a
selected file into an app-server-visible directory and reports waiting,
byte-progress, and completion states:

```swift
let uploader = AppServerFileUploader(
    destinationDirectory: workspace.appendingPathComponent("Attachments"),
    referenceRoot: workspace,
    maximumByteCount: 250 * 1024 * 1024
)

var uploaded: AppServerUploadedFile?
for try await state in uploader.uploadFile(at: selectedURL) {
    switch state {
    case .waiting:
        break
    case let .uploading(copied, total):
        print("Upload progress:", copied, "/", total)
    case let .completed(file):
        uploaded = file
    }
}
```

Build the corresponding `turn/start` input with
`AppServerTurnInputBuilder.make(text:attachments:)`. Images become typed
`localImage` inputs. Other files are listed by their workspace-relative paths
in the text input because the current app-server protocol has no general file
input variant.

## Event Handling

`AppServerClient.handleEvents()` reads messages from the app server. It resolves
pending client requests by JSON-RPC id, prints server requests and server
notifications, and falls back to pretty-printed JSON for messages that do not
decode into a known model.

For a real application, this is the likely place to replace the default
printing behavior with application-specific routing for:

- `AppServerModels.ServerRequest`
- `AppServerModels.ServerNotification`
- unknown JSON messages

## Regenerating OpenAPI and Mapping Code

The app-server protocol schemas are JSON Schema files. The Swift OpenAPI
generator is useful for models, but the package needs a reproducible OpenAPI
document and extra mapping glue for JSON-RPC requests and responses.

Run:

```sh
python3 Scripts/generate-openapi.py
```

This updates:

- `Sources/AppServerClient/openapi.json`
- `Sources/AppServerClient/Models/DataModelMapping.swift`

Then build to let the Swift OpenAPI plugin regenerate its derived sources:

```sh
swift build --target AppServerClient
```

## Notes

- The transport is JSON-RPC over newline-delimited JSON on stdio.
- `StdIOAppServerConnection.connect()` launches `/usr/bin/env codex app-server`.
- The checked-in OpenAPI input is generated from `openapi.json.template` and the
  schema files. Edit the schema generation script instead of hand-editing
  generated output.
- Generated OpenAPI plugin output lives under `.build` and is not checked in.
