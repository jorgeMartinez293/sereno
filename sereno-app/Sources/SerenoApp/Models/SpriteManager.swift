import Foundation
import AppKit

struct Sprite: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let filename: String
    let url: URL
    let isGIF: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(filename) }
    static func == (lhs: Sprite, rhs: Sprite) -> Bool { lhs.filename == rhs.filename }
}

class SpriteManager: ObservableObject {
    @Published var sprites: [Sprite] = []

    static let spritesDir: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/sereno/sprites")
    }()

    /// Sprites left behind by an old pokefetch install; read-only fallback until
    /// install.sh migrates them.
    static let legacySpritesDir: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/fastfetch/pokemons")
    }()

    init() { reload() }

    func reload() {
        let fm = FileManager.default
        let dir = fm.fileExists(atPath: Self.spritesDir.path) ? Self.spritesDir : Self.legacySpritesDir
        guard let files = try? fm.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        ) else { return }

        let valid = Set(["gif", "png", "jpg", "jpeg", "webp"])
        sprites = files
            .filter { valid.contains($0.pathExtension.lowercased()) }
            .map { url in
                let filename = url.lastPathComponent
                let name = url.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "_", with: " ")
                    .replacingOccurrences(of: "-", with: " ")
                    .capitalized
                return Sprite(name: name, filename: filename, url: url,
                               isGIF: url.pathExtension.lowercased() == "gif")
            }
            .sorted { $0.name < $1.name }
    }
}
