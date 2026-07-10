import Foundation

public struct AppServerUploadedFile: Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case file
        case image
    }

    public let id: UUID
    public let originalName: String
    public let url: URL
    public let referencePath: String
    public let byteCount: Int64
    public let mediaType: String?
    public let kind: Kind

    public init(
        id: UUID,
        originalName: String,
        url: URL,
        referencePath: String,
        byteCount: Int64,
        mediaType: String? = nil,
        kind: Kind
    ) {
        self.id = id
        self.originalName = originalName
        self.url = url
        self.referencePath = referencePath
        self.byteCount = byteCount
        self.mediaType = mediaType
        self.kind = kind
    }
}

public enum AppServerFileUploadState: Hashable, Sendable {
    case waiting
    case uploading(bytesCopied: Int64, totalBytes: Int64)
    case completed(AppServerUploadedFile)
}

public enum AppServerFileUploadError: Error, Equatable, LocalizedError, Sendable {
    case invalidSource(String)
    case fileTooLarge(limitBytes: Int64, actualBytes: Int64)
    case emptyData

    public var errorDescription: String? {
        switch self {
        case let .invalidSource(message):
            message
        case let .fileTooLarge(limitBytes, actualBytes):
            "The file is \(ByteCountFormatter.string(fromByteCount: actualBytes, countStyle: .file)); the limit is \(ByteCountFormatter.string(fromByteCount: limitBytes, countStyle: .file))."
        case .emptyData:
            "The selected item contains no data."
        }
    }
}

public struct AppServerFileUploader: Sendable {
    public let destinationDirectory: URL
    public let referenceRoot: URL?
    public let maximumByteCount: Int64?

    private let chunkSize = 512 * 1024

    public init(
        destinationDirectory: URL,
        referenceRoot: URL? = nil,
        maximumByteCount: Int64? = nil
    ) {
        self.destinationDirectory = destinationDirectory
        self.referenceRoot = referenceRoot
        self.maximumByteCount = maximumByteCount
    }

    public func uploadFile(
        at sourceURL: URL,
        fileName: String? = nil,
        kind: AppServerUploadedFile.Kind? = nil,
        mediaType: String? = nil,
        id: UUID = UUID()
    ) -> AsyncThrowingStream<AppServerFileUploadState, Error> {
        let destinationDirectory = self.destinationDirectory
        let referenceRoot = self.referenceRoot
        let maximumByteCount = self.maximumByteCount
        let chunkSize = self.chunkSize

        return AsyncThrowingStream { continuation in
            continuation.yield(.waiting)
            let task = Task.detached(priority: .userInitiated) {
                do {
                    let upload = try Self.copyFile(
                        at: sourceURL,
                        fileName: fileName,
                        kind: kind,
                        mediaType: mediaType,
                        id: id,
                        destinationDirectory: destinationDirectory,
                        referenceRoot: referenceRoot,
                        maximumByteCount: maximumByteCount,
                        chunkSize: chunkSize
                    ) { copied, total in
                        continuation.yield(.uploading(bytesCopied: copied, totalBytes: total))
                    }
                    continuation.yield(.completed(upload))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func uploadData(
        _ data: Data,
        fileName: String,
        kind: AppServerUploadedFile.Kind? = nil,
        mediaType: String? = nil,
        id: UUID = UUID()
    ) -> AsyncThrowingStream<AppServerFileUploadState, Error> {
        let destinationDirectory = self.destinationDirectory
        let referenceRoot = self.referenceRoot
        let maximumByteCount = self.maximumByteCount
        let chunkSize = self.chunkSize

        return AsyncThrowingStream { continuation in
            continuation.yield(.waiting)
            let task = Task.detached(priority: .userInitiated) {
                do {
                    let upload = try Self.copyData(
                        data,
                        fileName: fileName,
                        kind: kind,
                        mediaType: mediaType,
                        id: id,
                        destinationDirectory: destinationDirectory,
                        referenceRoot: referenceRoot,
                        maximumByteCount: maximumByteCount,
                        chunkSize: chunkSize
                    ) { copied, total in
                        continuation.yield(.uploading(bytesCopied: copied, totalBytes: total))
                    }
                    continuation.yield(.completed(upload))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

private extension AppServerFileUploader {
    typealias ProgressHandler = @Sendable (Int64, Int64) -> Void

    static func copyFile(
        at sourceURL: URL,
        fileName: String?,
        kind: AppServerUploadedFile.Kind?,
        mediaType: String?,
        id: UUID,
        destinationDirectory: URL,
        referenceRoot: URL?,
        maximumByteCount: Int64?,
        chunkSize: Int,
        progress: ProgressHandler
    ) throws -> AppServerUploadedFile {
        let accessedScope = startAccessingSecurityScope(sourceURL)
        defer { stopAccessingSecurityScope(sourceURL, accessed: accessedScope) }

        let values = try sourceURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile != false else {
            throw AppServerFileUploadError.invalidSource("Only regular files can be attached.")
        }
        let totalBytes = Int64(values.fileSize ?? 0)
        try validateSize(totalBytes, maximumByteCount: maximumByteCount)

        let originalName = sanitizedFileName(fileName ?? sourceURL.lastPathComponent)
        let destination = try prepareDestination(
            id: id,
            originalName: originalName,
            directory: destinationDirectory
        )
        let partial = destination.appendingPathExtension("partial")
        let fileManager = FileManager.default
        var completed = false
        defer {
            if !completed {
                try? fileManager.removeItem(at: partial)
            }
        }

        _ = fileManager.createFile(atPath: partial.path, contents: nil)
        let input = try FileHandle(forReadingFrom: sourceURL)
        let output = try FileHandle(forWritingTo: partial)
        defer {
            input.closeFile()
            output.closeFile()
        }

        var copied: Int64 = 0
        progress(copied, totalBytes)
        while true {
            try Task.checkCancellation()
            let chunk = input.readData(ofLength: chunkSize)
            guard !chunk.isEmpty else {
                break
            }
            output.write(chunk)
            copied += Int64(chunk.count)
            try validateSize(copied, maximumByteCount: maximumByteCount)
            progress(copied, totalBytes)
        }
        output.synchronizeFile()
        try fileManager.moveItem(at: partial, to: destination)
        completed = true

        return uploadedFile(
            id: id,
            originalName: originalName,
            destination: destination,
            referenceRoot: referenceRoot,
            byteCount: copied,
            mediaType: mediaType,
            kind: kind
        )
    }

    static func copyData(
        _ data: Data,
        fileName: String,
        kind: AppServerUploadedFile.Kind?,
        mediaType: String?,
        id: UUID,
        destinationDirectory: URL,
        referenceRoot: URL?,
        maximumByteCount: Int64?,
        chunkSize: Int,
        progress: ProgressHandler
    ) throws -> AppServerUploadedFile {
        guard !data.isEmpty else {
            throw AppServerFileUploadError.emptyData
        }
        let totalBytes = Int64(data.count)
        try validateSize(totalBytes, maximumByteCount: maximumByteCount)

        let originalName = sanitizedFileName(fileName)
        let destination = try prepareDestination(
            id: id,
            originalName: originalName,
            directory: destinationDirectory
        )
        let partial = destination.appendingPathExtension("partial")
        let fileManager = FileManager.default
        var completed = false
        defer {
            if !completed {
                try? fileManager.removeItem(at: partial)
            }
        }

        _ = fileManager.createFile(atPath: partial.path, contents: nil)
        let output = try FileHandle(forWritingTo: partial)
        defer { output.closeFile() }

        var offset = 0
        progress(0, totalBytes)
        while offset < data.count {
            try Task.checkCancellation()
            let end = min(offset + chunkSize, data.count)
            output.write(data[offset..<end])
            offset = end
            progress(Int64(offset), totalBytes)
        }
        output.synchronizeFile()
        try fileManager.moveItem(at: partial, to: destination)
        completed = true

        return uploadedFile(
            id: id,
            originalName: originalName,
            destination: destination,
            referenceRoot: referenceRoot,
            byteCount: totalBytes,
            mediaType: mediaType,
            kind: kind
        )
    }
}

private extension AppServerFileUploader {
    static let imageExtensions: Set<String> = [
        "avif", "bmp", "gif", "heic", "heif", "jpeg", "jpg", "png", "tif", "tiff", "webp"
    ]

    static func validateSize(_ size: Int64, maximumByteCount: Int64?) throws {
        if let maximumByteCount, size > maximumByteCount {
            throw AppServerFileUploadError.fileTooLarge(
                limitBytes: maximumByteCount,
                actualBytes: size
            )
        }
    }

    static func prepareDestination(id: UUID, originalName: String, directory: URL) throws -> URL {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(
            "\(id.uuidString.lowercased())-\(originalName)",
            isDirectory: false
        )
        try? fileManager.removeItem(at: destination)
        try? fileManager.removeItem(at: destination.appendingPathExtension("partial"))
        return destination
    }

    static func sanitizedFileName(_ proposedName: String) -> String {
        let lastComponent = URL(fileURLWithPath: proposedName).lastPathComponent
        let invalid = CharacterSet(charactersIn: "/\\:").union(.controlCharacters)
        let sanitized = lastComponent.unicodeScalars
            .map { invalid.contains($0) ? "_" : String($0) }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = sanitized.isEmpty || sanitized == "." || sanitized == ".." ? "attachment" : sanitized
        return String(fallback.prefix(180))
    }

    static func uploadedFile(
        id: UUID,
        originalName: String,
        destination: URL,
        referenceRoot: URL?,
        byteCount: Int64,
        mediaType: String?,
        kind: AppServerUploadedFile.Kind?
    ) -> AppServerUploadedFile {
        let inferredKind: AppServerUploadedFile.Kind
        if let kind {
            inferredKind = kind
        } else if mediaType?.lowercased().hasPrefix("image/") == true
            || imageExtensions.contains(destination.pathExtension.lowercased()) {
            inferredKind = .image
        } else {
            inferredKind = .file
        }

        return AppServerUploadedFile(
            id: id,
            originalName: originalName,
            url: destination,
            referencePath: relativePath(for: destination, root: referenceRoot),
            byteCount: byteCount,
            mediaType: mediaType,
            kind: inferredKind
        )
    }

    static func relativePath(for url: URL, root: URL?) -> String {
        guard let root else {
            return url.path
        }
        let rootComponents = root.standardizedFileURL.pathComponents
        let fileComponents = url.standardizedFileURL.pathComponents
        guard fileComponents.starts(with: rootComponents) else {
            return url.path
        }
        return fileComponents.dropFirst(rootComponents.count).joined(separator: "/")
    }

    static func startAccessingSecurityScope(_ url: URL) -> Bool {
        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
        url.startAccessingSecurityScopedResource()
        #else
        false
        #endif
    }

    static func stopAccessingSecurityScope(_ url: URL, accessed: Bool) {
        #if os(iOS) || os(macOS) || os(tvOS) || os(visionOS)
        if accessed {
            url.stopAccessingSecurityScopedResource()
        }
        #endif
    }
}
