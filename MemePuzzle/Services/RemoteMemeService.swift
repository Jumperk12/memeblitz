import Foundation
import SwiftUI
import UIKit

/// Response from GET /api/memes
public struct RemoteMemeCatalogResponse: Codable, Sendable {
    public let version: Int?
    public let timestamp: Double?
    public let count: Int
    public let memes: [RemoteMeme]
}

/// Service that discovers and syncs memes dropped onto the remote server or into the `memes_drop/` folder.
@Observable
public final class RemoteMemeService: @unchecked Sendable {
    public static let shared = RemoteMemeService()

    public var remoteMemes: [RemoteMeme] = []
    public var isSyncing: Bool = false
    public var lastSyncDate: Date? = nil
    public var syncError: String? = nil

    /// Server endpoint (local web server daemon on port 3000)
    public var serverBaseURL: URL = URL(string: "http://127.0.0.1:3000")!

    private let cacheDir: URL

    public init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDir = caches.appendingPathComponent("RemoteMemes", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.cacheDir, withIntermediateDirectories: true)
    }

    /// Fetches the remote catalog from the local server daemon.
    public func fetchCatalog() async {
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        let endpoint = serverBaseURL.appendingPathComponent("api/memes")
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 3.0
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(RemoteMemeCatalogResponse.self, from: data)
            let bundledIds = Set(MemeCatalog.bundled.map(\.id))

            // Only show memes that are remote / dropped beyond the bundled templates
            let newRemoteMemes = decoded.memes.filter { !bundledIds.contains($0.id) }

            await MainActor.run {
                self.remoteMemes = newRemoteMemes
                self.lastSyncDate = Date()
            }
        } catch {
            await MainActor.run {
                self.syncError = error.localizedDescription
            }
        }
    }

    /// Retrieves cached image from disk if available.
    public func cachedImage(for meme: RemoteMeme) -> UIImage? {
        let fileURL = cacheDir.appendingPathComponent(meme.filename)
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    /// Downloads the remote meme image, caches it to disk, and returns the UIImage.
    public func loadImage(for meme: RemoteMeme) async throws -> UIImage {
        if let cached = cachedImage(for: meme) {
            return cached
        }

        let imageURL = serverBaseURL.appendingPathComponent(meme.src)
        let (data, response) = try await URLSession.shared.data(from: imageURL)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        let fileURL = cacheDir.appendingPathComponent(meme.filename)
        try? data.write(to: fileURL)
        return image
    }
}
