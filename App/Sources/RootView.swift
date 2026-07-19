import SwiftUI
import SwiftData
import CoreKit
import DesignSystem

struct RootView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]

    private var tokens: ThemeTokens {
        themeManager.tokens(systemDark: colorScheme == .dark)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                Spacer()

                Image(systemName: "car.side.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(tokens.accentPrimary)

                Text("home.title")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(tokens.contentPrimary)

                Text("home.subtitle")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(tokens.contentSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)

                Spacer()

                PrimaryButton("home.newTrip", tokens: tokens) {
                    // Onboarding flow lands here (feature/s1-onboarding).
                }
                .padding(.horizontal, Spacing.l)
                .padding(.bottom, Spacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tokens.backgroundPrimary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    themePicker
                }
            }
        }
    }

    private var themePicker: some View {
        @Bindable var manager = themeManager
        return Picker("settings.theme", selection: $manager.mode) {
            Text("settings.theme.auto").tag(ThemeMode.auto)
            Text("settings.theme.light").tag(ThemeMode.light)
            Text("settings.theme.night").tag(ThemeMode.night)
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    RootView()
        .environment(ThemeManager())
        .modelContainer(try! CoreSchema.container(inMemory: true))
}
