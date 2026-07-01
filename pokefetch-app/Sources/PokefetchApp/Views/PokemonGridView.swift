import SwiftUI
import AppKit

struct PokemonGridView: View {
    let pokemons: [Pokemon]
    @Binding var selectedPokemon: Pokemon?
    @Binding var isRandomMode: Bool
    @Binding var searchText: String
    let accentColor: Color

    var filtered: [Pokemon] {
        searchText.isEmpty ? pokemons
        : pokemons.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let columns = [GridItem(.adaptive(minimum: 88, maximum: 110), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Buscar pokémon...", text: $searchText).textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    // Aleatorio card — always first
                    if searchText.isEmpty {
                        RandomCard(isSelected: isRandomMode, accentColor: accentColor)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.2)) {
                                    isRandomMode   = true
                                    selectedPokemon = nil
                                }
                            }
                    }

                    ForEach(filtered) { poke in
                        PokemonCell(
                            pokemon: poke,
                            isSelected: !isRandomMode && selectedPokemon == poke,
                            accentColor: accentColor
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.2)) {
                                isRandomMode    = false
                                selectedPokemon = poke
                            }
                        }
                    }
                }
                .padding(10)

                if filtered.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.diamond")
                            .font(.system(size: 36)).foregroundColor(.secondary)
                        Text("Sin resultados para \"\(searchText)\"")
                            .foregroundColor(.secondary).font(.callout)
                    }
                    .padding(.top, 40)
                }
            }

            Divider()
            HStack {
                Text("\(filtered.count) pokémon").font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
        }
    }
}

// MARK: - Random card
struct RandomCard: View {
    let isSelected: Bool
    let accentColor: Color
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.primary.opacity(hovered ? 0.07 : 0.03))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accentColor.opacity(0.9) : Color.clear, lineWidth: 2))
                    .shadow(color: isSelected ? accentColor.opacity(0.3) : .clear, radius: 8)

                Image(systemName: "dice.fill")
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? accentColor : .secondary)
                    .frame(width: 58, height: 58)
                    .padding(8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor).font(.system(size: 12)).padding(4)
                }
            }
            .frame(width: 88, height: 78)

            Text("Aleatorio")
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? accentColor : .primary)
                .lineLimit(1).frame(maxWidth: .infinity)
        }
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovered = h } }
    }
}

// MARK: - Pokemon cell
struct PokemonCell: View {
    let pokemon: Pokemon
    let isSelected: Bool
    let accentColor: Color
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.primary.opacity(hovered ? 0.07 : 0.03))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? accentColor.opacity(0.9) : Color.clear, lineWidth: 2))
                    .shadow(color: isSelected ? accentColor.opacity(0.3) : .clear, radius: 8)

                StaticGIFThumbnail(url: pokemon.url)
                    .frame(width: 58, height: 58).padding(8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor).font(.system(size: 12)).padding(4)
                }
            }
            .frame(width: 88, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(pokemon.name)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? accentColor : .primary)
                .lineLimit(1).frame(maxWidth: .infinity)
        }
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovered = h } }
    }
}

// MARK: - Static thumbnail (no animation)
struct StaticGIFThumbnail: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> NSImageView {
        let iv = NSImageView()
        iv.animates = false
        iv.imageScaling = .scaleProportionallyUpOrDown
        iv.imageFrameStyle = .none
        iv.wantsLayer = true
        iv.layer?.masksToBounds = true
        iv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        iv.setContentHuggingPriority(.defaultLow, for: .vertical)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        iv.image = NSImage(contentsOf: url)
        return iv
    }
    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(contentsOf: url)
    }
}
