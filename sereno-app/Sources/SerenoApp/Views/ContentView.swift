import SwiftUI
import AppKit

/// sereno's main window, dressed like vaho's settings (System Settings in dark mode):
/// a translucent "liquid glass" sidebar — here the list of available sprites — driving an
/// opaque dark detail column with the live terminal preview and controls. The sidebar picks
/// up a subtle tint from the selected sprite's dominant color. Changes persist immediately.
struct ContentView: View {
    @StateObject private var spriteManager = SpriteManager()

    @State private var config         = ConfigManager.load()
    @State private var selectedSprite: Sprite?
    @State private var isRandomMode   = false
    @State private var searchText     = ""
    @State private var saveStatus     = SaveStatus.idle
    @State private var isOnBattery    = ConfigManager.isOnBattery()
    @State private var accentColor    = Color(red: 0.85, green: 0.55, blue: 0.55)
    @State private var showPackStore  = false

    enum SaveStatus { case idle, saved, error }

    var body: some View {
        NavigationSplitView(columnVisibility: Binding(get: { .all }, set: { _ in })) {
            SpriteGridView(
                spriteManager: spriteManager,
                selectedSprite: $selectedSprite,
                isRandomMode: $isRandomMode,
                searchText: $searchText,
                accentColor: accentColor
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 460, max: 640)
            .background(SplitViewCollapseDisabler())
            // Native System-Settings-style search field at the top of the sidebar, exactly
            // like vaho's settings window.
            .searchable(text: $searchText, placement: .sidebar, prompt: "Buscar")
            // Drop the sidebar-collapse chevron. Applied to the sidebar content itself (not the
            // split view) so it also takes effect inside a WindowGroup.
            .hideSidebarToggle()
        } detail: {
            detail
        }
        .frame(minWidth: 900, minHeight: 580)
        .preferredColorScheme(.dark)
        .background(WindowChromeConfigurator())
        // Drop the toolbar's own material so the sidebar glass runs continuously up behind the
        // search field — no lighter/darker band where the toolbar meets the sidebar content.
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showPackStore = true } label: {
                    Image(systemName: "plus")
                }
                .help("Descargar packs de sprites")
            }
        }
        .sheet(isPresented: $showPackStore) {
            PackStoreView(spriteManager: spriteManager, accentColor: accentColor)
        }
        .onAppear(perform: restoreSelection)
        .onChange(of: selectedSprite) { poke in
            if let poke { computeColor(for: poke) }
            persist()
        }
        .onChange(of: isRandomMode) { random in
            if random { accentColor = Color(red: 0.85, green: 0.55, blue: 0.55) }
            persist()
        }
        .onChange(of: config.displayMode) { _ in persist() }
    }

    // MARK: - Detail

    private var detail: some View {
        VStack(spacing: 0) {
            PreviewView(
                sprite: isRandomMode ? spriteManager.sprites.randomElement() : selectedSprite,
                displayMode: config.displayMode,
                isOnBattery: isOnBattery
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            controlBar
        }
    }

    private var controlBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Modo de visualización")
                    .font(.caption).foregroundColor(.secondary)
                Picker("Modo", selection: $config.displayMode) {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Label(mode.label, systemImage: mode.icon).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 310)
            }

            Spacer()

            selectionIndicator

            Divider().frame(height: 34)

            saveIndicator
        }
        .animation(.easeInOut(duration: 0.2), value: saveStatus)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.bar)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isRandomMode {
            Label("Sprite aleatorio", systemImage: "dice.fill")
                .font(.caption).foregroundColor(.secondary)
        } else if let poke = selectedSprite {
            Label(poke.name, systemImage: "checkmark.circle.fill")
                .font(.caption).foregroundColor(.secondary)
        } else {
            Text("Ningún sprite seleccionado").font(.caption).foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var saveIndicator: some View {
        switch saveStatus {
        case .idle:
            Label("Guardado automático", systemImage: "checkmark.icloud")
                .font(.caption).foregroundColor(Color.secondary.opacity(0.6))
        case .saved:
            Label("Guardado", systemImage: "checkmark.circle.fill")
                .font(.caption).foregroundColor(.green)
        case .error:
            Label("Error al guardar", systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundColor(.orange)
        }
    }

    // MARK: - State

    private func restoreSelection() {
        if config.selectedSprite == nil {
            isRandomMode = true
            accentColor  = Color(red: 0.85, green: 0.55, blue: 0.55)
        } else if let saved = config.selectedSprite,
                  let poke  = spriteManager.sprites.first(where: { $0.filename == saved }) {
            selectedSprite = poke
            computeColor(for: poke)
        }
    }

    private func computeColor(for poke: Sprite) {
        DispatchQueue.global(qos: .userInitiated).async {
            let color = ColorExtractor.dominantColor(for: poke.url)
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.35)) { accentColor = color }
            }
        }
    }

    /// Persists the current selection + display mode immediately (vaho-style, no Save button).
    private func persist() {
        config.selectedSprite = isRandomMode ? nil : selectedSprite?.filename
        do {
            try ConfigManager.save(config)
            withAnimation { saveStatus = .saved }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { if saveStatus == .saved { saveStatus = .idle } }
            }
        } catch {
            withAnimation { saveStatus = .error }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { if saveStatus == .error { saveStatus = .idle } }
            }
        }
    }
}
