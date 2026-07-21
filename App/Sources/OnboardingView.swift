import SwiftUI
import SwiftData
import CoreKit
import GameEngine
import TripKit
import DesignSystem

/// Trip-creation flow (§2.1): travel type → travelers (name + avatar + age) →
/// driver → length → destination → generate board. Redesigned to be friendly
/// and visual, with names and avatars front-and-centre.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    let onCreated: (Trip) -> Void

    @State private var mode: TravelMode = .car
    @State private var length: TripLength = .medium
    @State private var destination = ""
    @State private var drafts: [TravelerDraft] = []
    @State private var editing: TravelerDraft?
    @State private var showAdd = false

    struct TravelerDraft: Identifiable, Equatable {
        var id = UUID()
        var name: String
        var age: Int
        var isDriver: Bool
        var avatarSymbol: String
        var avatarColorIndex: Int
    }

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }
    private var driverCount: Int { drafts.filter(\.isDriver).count }

    /// Car trips require exactly one driver (§2.1); planes and trains have none.
    private var canCreate: Bool {
        !drafts.isEmpty && (!mode.requiresDriver || driverCount == 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    travelTypeSection
                    travelersSection
                    lengthSection
                    destinationSection
                }
                .padding(Spacing.l)
                .padding(.bottom, 100)
            }
            .background(tokens.backgroundPrimary)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) { createBar }
            .navigationTitle("onboarding.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showAdd) {
                TravelerEditorSheet(mode: mode, existing: nil, suggestedIndex: drafts.count) { draft in
                    addOrUpdate(draft)
                }
            }
            .sheet(item: $editing) { draft in
                TravelerEditorSheet(mode: mode, existing: draft, suggestedIndex: 0) { updated in
                    addOrUpdate(updated)
                }
            }
        }
    }

    // MARK: sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("onboarding.heading")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(tokens.contentPrimary)
            Text("onboarding.subheading")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(tokens.contentSecondary)
        }
    }

    private var travelTypeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionTitle("onboarding.travelType")
            HStack(spacing: Spacing.s) {
                travelCard(.car, "onboarding.travelType.car")
                travelCard(.plane, "onboarding.travelType.plane")
                travelCard(.train, "onboarding.travelType.train")
            }
        }
    }

    private func travelCard(_ m: TravelMode, _ titleKey: LocalizedStringKey) -> some View {
        let selected = mode == m
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mode = m }
        } label: {
            VStack(spacing: Spacing.s) {
                Image(systemName: m.systemImage)
                    .font(.system(size: 28, weight: .bold))
                Text(titleKey)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(selected ? .white : tokens.contentSecondary)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(
                selected ? tokens.accentPrimary : tokens.surfaceCard,
                in: RoundedRectangle(cornerRadius: Radius.m)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(tokens.accentPrimary.opacity(selected ? 0 : 0.15), lineWidth: 1.5)
            )
        }
        .buttonStyle(BouncyButtonStyle())
        .accessibilityIdentifier("travelType.\(m.rawValue)")
    }

    private var travelersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionTitle("onboarding.travelers")
            ForEach(drafts) { draft in
                Button { editing = draft } label: { travelerRow(draft) }
                    .buttonStyle(BouncyButtonStyle())
            }
            Button { showAdd = true } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "plus.circle.fill")
                    Text("onboarding.addTraveler")
                }
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(tokens.accentPrimary)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(tokens.accentPrimary.opacity(0.10), in: RoundedRectangle(cornerRadius: Radius.m))
            }
            .buttonStyle(BouncyButtonStyle())
            .accessibilityIdentifier("btn.addTraveler")

            if mode.requiresDriver && !drafts.isEmpty && driverCount != 1 {
                Label("onboarding.driverHint", systemImage: "steeringwheel")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(tokens.accentWarning)
            }
        }
    }

    private func travelerRow(_ draft: TravelerDraft) -> some View {
        HStack(spacing: Spacing.m) {
            AvatarView(symbol: draft.avatarSymbol, colorIndex: draft.avatarColorIndex, size: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: draft.name)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(tokens.contentPrimary)
                Text("onboarding.ageValue \(draft.age)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(tokens.contentSecondary)
            }
            Spacer()
            if draft.isDriver && mode.requiresDriver {
                Image(systemName: "steeringwheel")
                    .foregroundStyle(tokens.accentPrimary)
            }
            Image(systemName: "pencil.circle.fill")
                .foregroundStyle(tokens.contentSecondary.opacity(0.5))
        }
        .padding(Spacing.m)
        .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.m))
    }

    private var lengthSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionTitle("onboarding.length")
            HStack(spacing: Spacing.s) {
                lengthPill(.short, "onboarding.length.short")
                lengthPill(.medium, "onboarding.length.medium")
                lengthPill(.long, "onboarding.length.long")
            }
        }
    }

    private func lengthPill(_ l: TripLength, _ titleKey: LocalizedStringKey) -> some View {
        let selected = length == l
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { length = l }
        } label: {
            Text(titleKey)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(selected ? .white : tokens.contentSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(selected ? tokens.accentPrimary : tokens.surfaceCard, in: Capsule())
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            sectionTitle("onboarding.destination")
            TextField("onboarding.destination.placeholder", text: $destination)
                .font(.system(.body, design: .rounded))
                .padding(Spacing.m)
                .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.m))
                .accessibilityIdentifier("field.destination")
        }
    }

    private var createBar: some View {
        PrimaryButton("onboarding.createTrip", tokens: tokens, icon: "sparkles") {
            createTrip()
        }
        .disabled(!canCreate)
        .opacity(canCreate ? 1 : 0.5)
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
        .background(.ultraThinMaterial)
        .accessibilityIdentifier("btn.createTrip")
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(tokens.contentPrimary)
    }

    // MARK: actions

    private func addOrUpdate(_ draft: TravelerDraft) {
        var next = draft
        // Exactly one driver on car trips.
        if next.isDriver {
            for i in drafts.indices where drafts[i].id != next.id { drafts[i].isDriver = false }
        }
        if let idx = drafts.firstIndex(where: { $0.id == next.id }) {
            drafts[idx] = next
        } else {
            if !mode.requiresDriver { next.isDriver = false }
            drafts.append(next)
        }
    }

    private func createTrip() {
        let travelers = drafts.map { draft in
            Traveler(
                name: draft.name,
                avatar: draft.avatarSymbol,
                avatarColorIndex: draft.avatarColorIndex,
                age: draft.age,
                isDriver: mode.requiresDriver && draft.isDriver
            )
        }
        let trip = TripBuilder.makeTrip(
            travelers: travelers,
            mode: mode,
            length: length,
            destinationName: destination.trimmingCharacters(in: .whitespaces).isEmpty ? nil : destination,
            manifests: GameRegistry.shared.allManifests
        )
        context.insert(trip)
        try? context.save()
        onCreated(trip)
    }
}
