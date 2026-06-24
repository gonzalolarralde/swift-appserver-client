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
            print("Thread: \(thread.name, default: "<Empty name>") \(thread.status)) \(thread.cwd) \(String(describing: thread.agentNickname)) \(String(describing: thread.agentRole)) \(thread.source)")
        }

        if let firstThread = threads.data.first {
            var cursor: String? = nil
            repeat {
                let turns = try await client.send(request: AppServerModels.ClientRequest.ThreadTurnsList.self, with: .init(cursor: nil, itemsView: .full, threadId: firstThread.id))
                for turn in turns.data {
                    print("Turn: \(turn.startedAt, default: "Start Unknown") - \(turn.completedAt, default: "End Unknown")")
                    print("\(turn.items.count) items")
                    switch turn.itemsView {
                    case .notLoaded: print("Not loaded")
                    case .summary: print("Summary")
                    case .full: print("Full")
                    case .none: print("Summary unknown")
                    }

                    for item in turn.items {
                        switch item {
                        case let .agentMessage(message): print("Agent Message: \(message.text)")
                        case let .collabAgentToolCall(collabAgentToolCall): print("Collab Agent Tool Call: \(collabAgentToolCall.tool)")
                        case let .commandExecution(command): print("Command: \(command.command)")
                        case let .contextCompaction(contextCompaction): print("Context compaction: \(contextCompaction)")
                        case let .dynamicToolCall(dynamicToolCall): print("Dynamic tool call: \(dynamicToolCall.tool)")
                        case let .enteredReviewMode(reviewMode): print("Entered review mode: \(reviewMode.review)")
                        case let .exitedReviewMode(reviewMode): print("Exited review mode: \(reviewMode.review)")
                        case let .fileChange(fileChange): print("File change: \(fileChange.changes) \(fileChange.status)")
                        case let .hookPrompt(hookPrompt): print("Hook prompt: \(hookPrompt.fragments)")
                        case let .imageGeneration(imageGeneration): print("Image generation: \(imageGeneration.savedPath, default: "no path") \(imageGeneration.revisedPrompt, default: imageGeneration.result)")
                        case let .imageView(imageView): print("Image view: \(imageView.path)")
                        case let .mcpToolCall(toolCall): print("Tool call: \(toolCall.tool)")
                        case let .plan(plan): print("Plan: \(plan.text)")
                        case let .reasoning(reasoning): print("Reasoning: \(reasoning.summary, default: "No reasoning summary")")
                        case let .sleep(sleep): print("Sleep: \(sleep.durationMs)")
                        case let .subAgentActivity(subAgentActivity): print("Sub Agent Activity: \(subAgentActivity.agentPath)")
                        case let .userMessage(message): print("User Message: \(message.content)")
                        case let .webSearch(webSearch): print("Web search: \(webSearch.query)")
                        }
                    }
                }
                cursor = turns.nextCursor
            } while cursor != nil
        }
    }
}
