import SwiftUI
import AppKit
import SwiftTerm

struct PreviewView: View {
    let sprite: Sprite?
    let displayMode: DisplayMode
    let isOnBattery: Bool

    private var showGIF: Bool {
        switch displayMode {
        case .gif:   return true
        case .image: return false
        case .auto:  return !isOnBattery
        }
    }

    // SF Mono 11pt line height (px) used to estimate terminal rows from view height
    private static let lineHeight: CGFloat = 15.0
    // Expected fastfetch output height in rows (logo + info side-by-side, max LOGO_HEIGHT=15 + margins)
    private static let outputRows = 17

    var body: some View {
        ZStack {
            Color(red: 0.10, green: 0.10, blue: 0.13)

            if sprite != nil {
                GeometryReader { geo in
                    let terminalRows = Int(geo.size.height / Self.lineHeight)
                    let topPadding   = max(0, (terminalRows - Self.outputRows) / 2)
                    TerminalPreviewView(
                        sprite: sprite,
                        displayMode: displayMode,
                        isOnBattery: isOnBattery,
                        topPadding: topPadding
                    )
                    .id("\(sprite?.filename ?? "")_\(displayMode.rawValue)_\(isOnBattery)_\(topPadding)")
                }
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 52)).foregroundColor(.white.opacity(0.18))
                    Text("Selecciona un sprite →")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            // Mode badge
            VStack {
                HStack {
                    Spacer()
                    Label(showGIF ? "GIF animado" : "Imagen estática",
                          systemImage: showGIF ? "play.circle.fill" : "photo.fill")
                        .font(.caption.monospaced())
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial.opacity(0.6))
                        .cornerRadius(6)
                        .padding(12)
                }
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(16)
    }
}

struct TerminalPreviewView: NSViewRepresentable {
    let sprite: Sprite?
    let displayMode: DisplayMode
    let isOnBattery: Bool
    let topPadding: Int

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        func processTerminated(source: TerminalView, exitCode: Int32?) {}
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let tv = LocalProcessTerminalView(frame: .zero)
        tv.processDelegate = context.coordinator
        tv.scrollerEnabled = false
        tv.nativeBackgroundColor = NSColor(red: 0.10, green: 0.10, blue: 0.13, alpha: 1.0)
        tv.nativeForegroundColor = .white
        tv.caretColor = .white
        tv.font = NSFont(name: "SF Mono", size: 11) ?? NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        startProcess(in: tv)
        return tv
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {}

    static func dismantleNSView(_ nsView: LocalProcessTerminalView, coordinator: Coordinator) {
        nsView.processDelegate = nil
        nsView.terminate()
    }

    private func startProcess(in tv: LocalProcessTerminalView) {
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        let currentPath = env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:\(currentPath)"
        if let sprite {
            env["SERENO_PREVIEW"] = sprite.url.path
        }
        env["SERENO_PREVIEW_MODE"] = displayMode.rawValue

        let script = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/sereno/greet.sh")
            .path

        let command = topPadding > 0
            ? "printf '\\n%.0s' {1..\(topPadding)}; \(script)"
            : script

        tv.startProcess(
            executable: "/bin/zsh",
            args: ["-c", command],
            environment: env.map { "\($0.key)=\($0.value)" }
        )
    }
}
