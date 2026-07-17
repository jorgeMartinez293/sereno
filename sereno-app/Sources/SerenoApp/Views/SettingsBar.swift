import SwiftUI

struct SettingsBar: View {
    @Binding var config: SerenoConfig
    let selectedSprite: Sprite?
    let isRandom: Bool
    let saveStatus: ContentView.SaveStatus
    let accentColor: Color
    let onSave: () -> Void

    var body: some View {
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
                .frame(width: 310)
            }

            Spacer()

            // Selection indicator
            if isRandom {
                HStack(spacing: 5) {
                    Image(systemName: "dice.fill").font(.caption).foregroundColor(.secondary)
                    Text("Sprite aleatorio").font(.caption).foregroundColor(.secondary)
                }
            } else if let poke = selectedSprite {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill").font(.caption).foregroundColor(.secondary)
                    Text(poke.name).font(.caption).foregroundColor(.secondary)
                }
            } else {
                Text("Ningún sprite seleccionado").font(.caption).foregroundColor(.secondary)
            }

            Divider().frame(height: 40)

            Button(action: onSave) {
                HStack(spacing: 5) {
                    switch saveStatus {
                    case .idle:
                        Image(systemName: "square.and.arrow.down"); Text("Guardar")
                    case .saved:
                        Image(systemName: "checkmark.circle.fill"); Text("¡Guardado!")
                    case .error:
                        Image(systemName: "exclamationmark.triangle.fill"); Text("Error")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(saveStatus == .saved ? .green : saveStatus == .error ? .orange : accentColor)
            .disabled(!isRandom && selectedSprite == nil)
            .animation(.easeInOut(duration: 0.2), value: saveStatus)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(.bar)
    }
}
