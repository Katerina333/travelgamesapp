import SwiftUI
import SwiftData
import CoreKit
import GameEngine
import TripKit
import DesignSystem

/// Lets the player choose which games are on this trip's board. Shows every
/// game playable for the trip's mode/players; toggling writes `trip.gameBoard`.
struct GamePickerSheet: View {
    let trip: Trip

    @Environment(\.modelContext) private var context
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<String>

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }

    init(trip: Trip) {
        self.trip = trip
        _selected = State(initialValue: Set(trip.gameBoard))
    }

    /// All games playable for this trip (mode + players + quiet), ordered by fit.
    private var playable: [GameManifest] {
        GameBoardGenerator.recommendedManifests(
            from: GameRegistry.shared.allManifests,
            players: trip.travelers.map(\.playerContext),
            mode: trip.travelMode,
            quietMode: trip.quietMode
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    Text("gamePicker.subtitle")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(tokens.contentSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Array(playable.enumerated()), id: \.element.id) { index, manifest in
                        row(manifest, colorIndex: index)
                    }
                }
                .padding(Spacing.l)
            }
            .background(tokens.backgroundPrimary)
            .navigationTitle("gamePicker.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done", action: save)
                        .fontWeight(.bold)
                        .disabled(selected.isEmpty)
                        .accessibilityIdentifier("btn.gamePickerDone")
                }
            }
        }
    }

    private func row(_ manifest: GameManifest, colorIndex: Int) -> some View {
        let isOn = selected.contains(manifest.id)
        let color = AvatarCatalog.color(colorIndex)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isOn { selected.remove(manifest.id) } else { selected.insert(manifest.id) }
            }
        } label: {
            HStack(spacing: Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.m).fill(color.opacity(0.18))
                    Image(systemName: manifest.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(color)
                }
                .frame(width: 48, height: 48)

                Text(LocalizedStringKey(manifest.nameKey))
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(tokens.contentPrimary)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isOn ? tokens.accentSuccess : tokens.contentSecondary.opacity(0.4))
            }
            .padding(Spacing.m)
            .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.m))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(isOn ? tokens.accentSuccess.opacity(0.4) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityIdentifier("gamePicker.row.\(manifest.id)")
    }

    private func save() {
        // Preserve fit order from the playable list.
        trip.gameBoard = playable.map(\.id).filter { selected.contains($0) }
        try? context.save()
        dismiss()
    }
}
