import SwiftUI
import CoreKit
import DesignSystem

/// Add or edit a traveler — name and avatar are the hero of this screen, with
/// age and (car-only) driver below. Addresses "add names, not only age".
struct TravelerEditorSheet: View {
    let mode: TravelMode
    let existing: OnboardingView.TravelerDraft?
    let suggestedIndex: Int
    let onSave: (OnboardingView.TravelerDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var name: String
    @State private var age: Int
    @State private var isDriver: Bool
    @State private var symbolIndex: Int
    @State private var colorIndex: Int

    private var tokens: ThemeTokens { themeManager.tokens(systemDark: colorScheme == .dark) }
    private let draftID: UUID

    init(mode: TravelMode, existing: OnboardingView.TravelerDraft?, suggestedIndex: Int,
         onSave: @escaping (OnboardingView.TravelerDraft) -> Void) {
        self.mode = mode
        self.existing = existing
        self.suggestedIndex = suggestedIndex
        self.onSave = onSave
        self.draftID = existing?.id ?? UUID()
        _name = State(initialValue: existing?.name ?? "")
        _age = State(initialValue: existing?.age ?? 8)
        _isDriver = State(initialValue: existing?.isDriver ?? false)
        let symIdx = existing.flatMap { AvatarCatalog.symbols.firstIndex(of: $0.avatarSymbol) } ?? (suggestedIndex % AvatarCatalog.symbols.count)
        _symbolIndex = State(initialValue: symIdx)
        _colorIndex = State(initialValue: existing?.avatarColorIndex ?? (suggestedIndex % AvatarCatalog.colors.count))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    // Big avatar preview
                    AvatarView(symbol: AvatarCatalog.symbol(symbolIndex), colorIndex: colorIndex, size: 96)
                        .padding(.top, Spacing.m)

                    // Name — the hero field
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("onboarding.traveler.name")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(tokens.contentSecondary)
                        TextField("", text: $name, prompt: Text("onboarding.traveler.namePrompt"))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(tokens.contentPrimary)
                            .textInputAutocapitalization(.words)
                            .padding(Spacing.m)
                            .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.m))
                            .accessibilityIdentifier("field.travelerName")
                    }

                    // Driver marking — kept near the top so it's never missed
                    // on car trips (§1.2).
                    if mode.requiresDriver {
                        Toggle(isOn: $isDriver) {
                            Label("onboarding.traveler.driver", systemImage: "steeringwheel")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(tokens.contentPrimary)
                        }
                        .tint(tokens.accentPrimary)
                        .padding(Spacing.m)
                        .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.m))
                        .accessibilityIdentifier("toggle.driver")
                    }

                    // Avatar symbol picker
                    pickerRow(title: "onboarding.traveler.pickAvatar") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.s) {
                                ForEach(AvatarCatalog.symbols.indices, id: \.self) { i in
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { symbolIndex = i }
                                    } label: {
                                        Image(systemName: AvatarCatalog.symbols[i])
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundStyle(symbolIndex == i ? .white : tokens.contentSecondary)
                                            .frame(width: 52, height: 52)
                                            .background(symbolIndex == i ? tokens.accentPrimary : tokens.surfaceCard, in: Circle())
                                    }
                                    .buttonStyle(BouncyButtonStyle())
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }

                    // Avatar color picker
                    pickerRow(title: "onboarding.traveler.pickColor") {
                        HStack(spacing: Spacing.s) {
                            ForEach(AvatarCatalog.colors.indices, id: \.self) { i in
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { colorIndex = i }
                                } label: {
                                    Circle()
                                        .fill(AvatarCatalog.color(i))
                                        .frame(width: 40, height: 40)
                                        .overlay(Circle().strokeBorder(.white, lineWidth: colorIndex == i ? 3 : 0))
                                        .overlay(Circle().strokeBorder(tokens.contentSecondary.opacity(0.2), lineWidth: 1))
                                        .scaleEffect(colorIndex == i ? 1.12 : 1)
                                }
                                .buttonStyle(BouncyButtonStyle())
                            }
                        }
                    }

                    // Age
                    pickerRow(title: "onboarding.traveler.age") {
                        Picker("onboarding.traveler.age", selection: $age) {
                            ForEach(1..<100, id: \.self) { Text(verbatim: "\($0)").tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 110)
                        .accessibilityIdentifier("picker.age")
                    }
                }
                .padding(Spacing.l)
            }
            .background(tokens.backgroundPrimary)
            .navigationTitle(existing == nil ? "onboarding.addTraveler" : "onboarding.editTraveler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save", action: save)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("btn.saveTraveler")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func pickerRow<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(tokens.contentSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let finalName = trimmed.isEmpty ? String(localized: "onboarding.defaultName \(suggestedIndex + 1)") : trimmed
        onSave(OnboardingView.TravelerDraft(
            id: draftID,
            name: finalName,
            age: age,
            isDriver: mode.requiresDriver && isDriver,
            avatarSymbol: AvatarCatalog.symbol(symbolIndex),
            avatarColorIndex: colorIndex
        ))
        dismiss()
    }
}
