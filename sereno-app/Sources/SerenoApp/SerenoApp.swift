import SwiftUI
import AppKit
import Sparkle

@main
struct SerenoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("sereno") {
            ContentView()
                .frame(minWidth: 900, minHeight: 580)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                CheckForUpdatesButton(updater: appDelegate.updaterController)
                Button("Instalar sereno en el terminal…") {
                    AppDelegate.launchInstaller()
                }
            }
        }
    }
}

struct CheckForUpdatesButton: View {
    let updater: SPUStandardUpdaterController
    var body: some View {
        Button("Buscar actualizaciones…") { updater.checkForUpdates(nil) }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    /// Sparkle auto-updates: checks the appcast on the sereno-releases repo's gh-pages.
    let updaterController = SPUStandardUpdaterController(startingUpdater: true,
                                                         updaterDelegate: nil,
                                                         userDriverDelegate: nil)

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        offerInstallIfMissing()
    }

    /// The .app is what non-technical users download; the greeter itself lives in
    /// ~/.config/sereno and is set up by the bundled install.sh. If it isn't there
    /// yet, offer to run the installer in Terminal.
    private func offerInstallIfMissing() {
        let greet = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/sereno/greet.sh")
        guard !FileManager.default.fileExists(atPath: greet.path) else { return }

        let alert = NSAlert()
        alert.messageText = "sereno aún no está instalado en tu terminal"
        alert.informativeText = "Para que te salude al abrir el terminal hay que instalar sus scripts (se abrirá Terminal y tardará un par de minutos la primera vez)."
        alert.addButton(withTitle: "Instalar")
        alert.addButton(withTitle: "Ahora no")
        if alert.runModal() == .alertFirstButtonReturn {
            Self.launchInstaller()
        }
    }

    /// Runs the bundled install.sh in Terminal (visible progress, asks for nothing else).
    static func launchInstaller() {
        guard let installer = Bundle.main.url(forResource: "install",
                                              withExtension: "sh",
                                              subdirectory: "installer") else { return }
        let terminal = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([installer], withApplicationAt: terminal,
                                configuration: config, completionHandler: nil)
    }
}
