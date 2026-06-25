import AppServerClient
import Foundation

@main
struct Main {
    static func main() async throws {
        print("Codex app-server smoke demo")
        print("Starting `codex app-server` over stdio...")

        let connection = try StdIOAppServerConnection.connect()
        let client = AppServerClient(connection: connection)

        Task {
            await client.handleEvents(logMessages: false)
        }

        let initResult = try await client.sendInitialize()
        section("Runtime")
        field("Codex home", String(describing: initResult.codexHome))
        field("Platform", "\(initResult.platformFamily) / \(initResult.platformOs)")
        field("User agent", initResult.userAgent)

        let account = try await client.send(
            request: AppServerModels.ClientRequest.AccountRead.self,
            with: .init()
        )
        section("Account")
        field("Status", describeAccount(account.account))
        field("Requires OpenAI auth", account.requiresOpenaiAuth ? "yes" : "no")

        let usage = try await client.send(
            request: AppServerModels.ClientRequest.AccountUsageRead.self,
            with: .init()
        )
        section("Usage")
        field("Lifetime tokens", usage.summary.lifetimeTokens.map(formatNumber) ?? "unknown")
        field("Current streak", usage.summary.currentStreakDays.map { "\($0) days" } ?? "unknown")
        field("Peak daily tokens", usage.summary.peakDailyTokens.map(formatNumber) ?? "unknown")

        let threads = try await client.send(
            request: AppServerModels.ClientRequest.ThreadList.self,
            with: .init(limit: 5)
        )
        section("Recent Threads")
        if threads.data.isEmpty {
            print("No recent threads returned.")
            return
        }

        for (index, thread) in threads.data.enumerated() {
            print("\(index + 1). \(threadTitle(thread))")
            print("   \(describeThread(thread))")
            print("   \(singleLine(thread.preview, maxLength: 120))")
        }

        guard let featuredThread = threads.data.first else {
            return
        }

        let turns = try await client.send(
            request: AppServerModels.ClientRequest.ThreadTurnsList.self,
            with: .init(itemsView: .full, limit: 3, threadId: featuredThread.id)
        )

        section("Featured Thread")
        field("Title", threadTitle(featuredThread))
        field("Thread id", featuredThread.id)
        field("Turns returned", "\(turns.data.count)")

        for turn in turns.data {
            print("")
            print("Turn \(shortID(turn.id)) - \(turn.status) - \(describeDuration(turn.durationMs))")
            print("Items: \(turn.items.count) \(describeItemBreakdown(turn.items))")

            for item in turn.items.prefix(6) {
                print("  - \(describeItem(item))")
            }

            if turn.items.count > 6 {
                print("  - ... \(turn.items.count - 6) more items")
            }
        }

        if turns.nextCursor != nil {
            print("")
            print("More turns are available through pagination.")
        }
    }
}

private func section(_ title: String) {
    print("")
    print("== \(title) ==")
}

private func field(_ name: String, _ value: String) {
    print("\(name): \(value)")
}

private func describeAccount(_ account: Components.Schemas.Account?) -> String {
    switch account {
    case .amazonBedrock:
        return "Amazon Bedrock"
    case .apiKey:
        return "API key"
    case let .chatgpt(chatGPT):
        return "ChatGPT (\(chatGPT.email), \(chatGPT.planType))"
    case .none:
        return "not signed in"
    }
}

private func threadTitle(_ thread: Components.Schemas.Thread) -> String {
    let title = thread.name?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let title, !title.isEmpty {
        return title
    }
    return "<Untitled thread>"
}

private func describeThread(_ thread: Components.Schemas.Thread) -> String {
    var parts = [
        describeThreadStatus(thread.status),
        thread.modelProvider,
        describeSessionSource(thread.source),
        String(describing: thread.cwd),
    ]

    if let agentNickname = thread.agentNickname {
        parts.insert("agent: \(agentNickname)", at: 1)
    }

    return parts.joined(separator: " | ")
}

private func describeThreadStatus(_ status: Components.Schemas.ThreadStatus) -> String {
    switch status {
    case let .active(active):
        if active.activeFlags.isEmpty {
            return "active"
        }
        let flags = active.activeFlags.map(String.init(describing:)).joined(separator: ", ")
        return "active (\(flags))"
    case .idle:
        return "idle"
    case .notLoaded:
        return "not loaded"
    case .systemError:
        return "system error"
    }
}

private func describeSessionSource(_ source: Components.Schemas.SessionSource) -> String {
    switch source {
    case let .case1(value):
        return String(describing: value)
    case let .case2(value):
        return value.custom
    case let .case3(value):
        return "sub-agent: \(describeSubAgentSource(value.subAgent))"
    }
}

private func describeSubAgentSource(_ source: Components.Schemas.SubAgentSource) -> String {
    switch source {
    case let .case1(value):
        return String(describing: value)
    case let .case2(value):
        let spawn = value.threadSpawn
        return spawn.agentNickname ?? spawn.agentPath ?? "thread spawn"
    case let .case3(value):
        return value.other
    }
}

private func describeItem(_ item: Components.Schemas.ThreadItem) -> String {
    switch item {
    case let .agentMessage(message):
        return "agent: \(singleLine(message.text))"
    case let .userMessage(message):
        return "user input: \(message.content.count) part(s)"
    case let .commandExecution(command):
        return "command: \(singleLine(command.command)) [\(command.status)]"
    case let .fileChange(fileChange):
        return "file change: \(fileChange.changes.count) change(s), \(fileChange.status)"
    case let .mcpToolCall(toolCall):
        return "MCP tool: \(toolCall.tool) [\(toolCall.status)]"
    case let .dynamicToolCall(toolCall):
        return "dynamic tool: \(toolCall.tool) [\(toolCall.status)]"
    case let .collabAgentToolCall(toolCall):
        return "collab agent tool: \(toolCall.tool)"
    case let .plan(plan):
        return "plan: \(singleLine(plan.text))"
    case let .reasoning(reasoning):
        return "reasoning: \(reasoning.summary?.count ?? 0) summary part(s)"
    case let .webSearch(webSearch):
        return "web search: \(singleLine(webSearch.query))"
    case let .imageView(imageView):
        return "image viewed: \(imageView.path)"
    case let .imageGeneration(imageGeneration):
        return "image generation: \(imageGeneration.status)"
    case let .hookPrompt(hookPrompt):
        return "hook prompt: \(hookPrompt.fragments.count) fragment(s)"
    case let .sleep(sleep):
        return "sleep: \(describeDuration(Int64(sleep.durationMs)))"
    case let .subAgentActivity(activity):
        return "sub-agent activity: \(activity.agentPath)"
    case let .enteredReviewMode(reviewMode):
        return "entered review mode: \(reviewMode.review)"
    case let .exitedReviewMode(reviewMode):
        return "exited review mode: \(reviewMode.review)"
    case .contextCompaction:
        return "context compaction"
    }
}

private func itemKind(_ item: Components.Schemas.ThreadItem) -> String {
    switch item {
    case .agentMessage: return "agent"
    case .collabAgentToolCall: return "collab-tool"
    case .commandExecution: return "command"
    case .contextCompaction: return "compaction"
    case .dynamicToolCall: return "dynamic-tool"
    case .enteredReviewMode: return "review-enter"
    case .exitedReviewMode: return "review-exit"
    case .fileChange: return "file"
    case .hookPrompt: return "hook"
    case .imageGeneration: return "image-gen"
    case .imageView: return "image"
    case .mcpToolCall: return "mcp"
    case .plan: return "plan"
    case .reasoning: return "reasoning"
    case .sleep: return "sleep"
    case .subAgentActivity: return "sub-agent"
    case .userMessage: return "user"
    case .webSearch: return "web"
    }
}

private func describeItemBreakdown(_ items: [Components.Schemas.ThreadItem]) -> String {
    let counts = Dictionary(grouping: items, by: itemKind).mapValues(\.count)
    let summary = counts
        .sorted { $0.key < $1.key }
        .map { "\($0.key): \($0.value)" }
        .joined(separator: ", ")
    return summary.isEmpty ? "" : "(\(summary))"
}

private func describeDuration(_ milliseconds: Int64?) -> String {
    guard let milliseconds else {
        return "duration unknown"
    }

    if milliseconds < 1_000 {
        return "\(milliseconds) ms"
    }

    let seconds = Double(milliseconds) / 1_000
    return String(format: "%.1f s", seconds)
}

private func shortID(_ id: String) -> String {
    String(id.prefix(8))
}

private func singleLine(_ text: String, maxLength: Int = 96) -> String {
    let collapsed = text
        .split(whereSeparator: \.isNewline)
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    guard collapsed.count > maxLength else {
        return collapsed
    }

    let endIndex = collapsed.index(collapsed.startIndex, offsetBy: maxLength)
    return "\(collapsed[..<endIndex])..."
}

private func formatNumber(_ value: Int64) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
