import Foundation

enum DisplayMode: String, Codable, CaseIterable {
    case gif   = "gif"
    case image = "image"
    case auto  = "auto"

    var label: String {
        switch self {
        case .gif:   return "GIF"
        case .image: return "Imagen"
        case .auto:  return "Auto (batería)"
        }
    }
    var icon: String {
        switch self {
        case .gif:   return "play.circle"
        case .image: return "photo"
        case .auto:  return "bolt.badge.automatic"
        }
    }
}

struct SerenoConfig: Codable {
    var selectedSprite: String?
    var displayMode: DisplayMode

    enum CodingKeys: String, CodingKey {
        case selectedSprite = "selected_sprite"
        // Pre-rename (pokefetch) key, read as a decode fallback.
        case legacySelectedSprite = "selected_pokemon"
        case displayMode = "display_mode"
    }
    init(selectedSprite: String? = nil, displayMode: DisplayMode = .auto) {
        self.selectedSprite = selectedSprite
        self.displayMode     = displayMode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.selectedSprite = try c.decodeIfPresent(String.self, forKey: .selectedSprite)
            ?? c.decodeIfPresent(String.self, forKey: .legacySelectedSprite)
        self.displayMode = try c.decodeIfPresent(DisplayMode.self, forKey: .displayMode) ?? .auto
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(selectedSprite, forKey: .selectedSprite)
        try c.encode(displayMode, forKey: .displayMode)
    }
}

class ConfigManager {
    static let configURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/sereno/config.json")
    }()

    /// Config left behind by an old pokefetch install; read-only fallback until
    /// install.sh migrates it.
    static let legacyConfigURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/fastfetch/pokefetch_config.json")
    }()

    static func load() -> SerenoConfig {
        for url in [configURL, legacyConfigURL] {
            if let data = try? Data(contentsOf: url),
               let cfg = try? JSONDecoder().decode(SerenoConfig.self, from: data) {
                return cfg
            }
        }
        return SerenoConfig()
    }

    static func save(_ config: SerenoConfig) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        let data = try enc.encode(config)
        try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: configURL, options: .atomic)
    }

    static func isOnBattery() -> Bool {
        shell("pmset -g batt 2>/dev/null | head -n 1").contains("Battery Power")
    }

    @discardableResult
    static func shell(_ cmd: String) -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments  = ["-c", cmd]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                      encoding: .utf8) ?? ""
    }
}
