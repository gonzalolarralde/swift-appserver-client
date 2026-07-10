import Foundation

public enum AppServerTurnInputBuilder {
    public static func make(
        text: String,
        attachments: [AppServerUploadedFile]
    ) -> [Components.Schemas.UserInput] {
        let files = attachments.filter { $0.kind == .file }
        var message = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if !files.isEmpty {
            let references = files
                .map { "- `\(escapedReference($0.referencePath))`" }
                .joined(separator: "\n")
            let attachmentText = "Attached files (available in the workspace):\n\(references)"
            message = message.isEmpty ? attachmentText : "\(message)\n\n\(attachmentText)"
        }

        var input: [Components.Schemas.UserInput] = []
        if !message.isEmpty {
            input.append(.text(.init(text: message, _type: .text)))
        }
        input.append(contentsOf: attachments.compactMap { attachment in
            guard attachment.kind == .image else {
                return nil
            }
            return .localImage(.init(
                path: attachment.url.path,
                _type: .localImage
            ))
        })
        return input
    }

    private static func escapedReference(_ reference: String) -> String {
        reference.replacingOccurrences(of: "`", with: "\\`")
    }
}
