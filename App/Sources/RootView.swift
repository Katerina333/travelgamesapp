import SwiftUI
import SwiftData
import CoreKit
import DesignSystem

struct RootView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]

    @State private var path: [Trip] = []
    @State private var showOnboarding = false
    @State private var showSettings = false

    private var tokens: ThemeTokens {
        themeManager.tokens(systemDark: colorScheme == .dark)
    }

    private var ongoingTrip: Trip? {
        trips.first { $0.status == .active || $0.status == .paused }
    }

    private var completedTrips: [Trip] {
        trips.filter { $0.status == .completed }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    header

                    if let trip = ongoingTrip {
                        continueCard(trip)
                    }

                    PrimaryButton("home.newTrip", tokens: tokens) {
                        showOnboarding = true
                    }
                    .accessibilityIdentifier("btn.newTrip")

                    if !completedTrips.isEmpty {
                        historySection
                    }
                }
                .padding(Spacing.l)
            }
            .background(tokens.backgroundPrimary)
            .navigationDestination(for: Trip.self) { TripView(trip: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(tokens.contentSecondary)
                    }
                    .accessibilityIdentifier("btn.settings")
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { trip in
                showOnboarding = false
                path = [trip]
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 56))
                .foregroundStyle(tokens.accentPrimary)
            Text("home.title")
                .font(.system(.largeTitle, design: .rounded).bold())
                .foregroundStyle(tokens.contentPrimary)
            Text("home.subtitle")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(tokens.contentSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xl)
    }

    private func continueCard(_ trip: Trip) -> some View {
        Button {
            path = [trip]
        } label: {
            HStack(spacing: Spacing.m) {
                Image(systemName: trip.travelMode.systemImage)
                    .font(.title2)
                    .foregroundStyle(tokens.accentPrimary)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("home.continueTrip")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(tokens.contentPrimary)
                    if let destination = trip.destinationName {
                        Text(verbatim: destination)
                            .font(.subheadline)
                            .foregroundStyle(tokens.contentSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(tokens.contentSecondary)
            }
            .padding(Spacing.m)
            .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.m))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("btn.continueTrip")
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("home.history")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(tokens.contentSecondary)
            ForEach(completedTrips) { trip in
                Button {
                    path = [trip]
                } label: {
                    HStack {
                        Image(systemName: trip.travelMode.systemImage)
                            .foregroundStyle(tokens.contentSecondary)
                        Text(verbatim: trip.destinationName ?? trip.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(tokens.contentPrimary)
                        Spacer()
                    }
                    .padding(Spacing.m)
                    .background(tokens.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.s))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
