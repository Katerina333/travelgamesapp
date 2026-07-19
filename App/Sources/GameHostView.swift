import SwiftUI
import SwiftData
import CoreKit
import GameEngine
import TripKit
import PaywallKit
import DesignSystem

/// Hosts one game round: builds the session (fresh or resumed), persists every
/// mutation to SwiftData (§2.2 zero data loss), and runs the playtime meter
/// with its warning banner and blocking gate (§2.3).
struct GameHostView: View {
    let trip: Trip
    let game: any TripGame

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var session: GameSession?
    @State private var meter: PlaytimeMeter?
    @State private var meterState: MeterState = .playing(remaining: PlaytimeMeter.freeLimitSeconds)

    private var tokens: ThemeTokens {
        themeManager.tokens(systemDark: colorScheme == .dark)
    }

    var body: some View {
        ZStack {
            tokens.backgroundPrimary.ignoresSafeArea()

            if let session {
                game.makePlayView(session: session)
            } else {
                ProgressView()
            }

            if case .warning(let remaining) = meterState {
                warningBanner(remaining: remaining)
            }
            if meterState == .locked {
                lockedOverlay
            }
        }
        .navigationTitle(Text(LocalizedStringKey(game.manifest.nameKey)))
        .navigationBarTitleDisplayMode(.inline)
        .task { await runMeter() }
        .onAppear(perform: setupSession)
        .onDisappear {
            let meter = meter
            Task { await meter?.gamePaused() }
        }
        .onChange(of: scenePhase) { _, phase in
            let meter = meter
            if phase == .active {
                if session != nil { Task { await meter?.gameStarted() } }
            } else {
                // Backgrounding pauses metering and flushes state (§2.2/§2.3).
                try? context.save()
                Task { await meter?.gamePaused() }
            }
        }
    }

    private func setupSession() {
        guard session == nil else { return }
        let gameID = game.manifest.id
        let record: GameSessionRecord
        if let open = trip.sessions.first(where: { $0.gameID == gameID && $0.endedAt == nil }) {
            record = open
        } else {
            record = GameSessionRecord(gameID: gameID)
            trip.sessions.append(record)
        }

        let newSession = GameSession(
            manifest: game.manifest,
            players: trip.travelers.map(\.playerContext),
            scores: record.scores,
            resumePayload: record.resumeState
        )
        newSession.onChange = { [weak newSession] in
            guard let newSession else { return }
            record.scores = newSession.scores
            record.resumeState = newSession.resumePayload
            if newSession.isFinished {
                record.endedAt = .now
            }
            try? context.save()
            if newSession.isFinished {
                dismiss()
            }
        }
        session = newSession
    }

    private func runMeter() async {
        let activeMeter = meter ?? PlaytimeMeter(
            tripID: trip.id,
            store: TripPlaytimeStore(container: context.container)
        )
        meter = activeMeter
        await activeMeter.gameStarted()
        while !Task.isCancelled {
            await activeMeter.heartbeat()
            let state = await activeMeter.state()
            meterState = state
            if state == .locked {
                await activeMeter.gamePaused()
                break
            }
            try? await Task.sleep(for: .seconds(10))
        }
    }

    private func warningBanner(remaining: Double) -> some View {
        VStack {
            HStack(spacing: Spacing.s) {
                Image(systemName: "clock.badge.exclamationmark")
                Text("meter.warning")
                Text(verbatim: timeString(remaining))
                    .monospacedDigit()
            }
            .font(.system(.subheadline, design: .rounded).bold())
            .foregroundStyle(tokens.contentPrimary)
            .padding(Spacing.m)
            .background(tokens.accentWarning.opacity(0.25), in: Capsule())
            Spacer()
        }
        .padding(.top, Spacing.s)
        .allowsHitTesting(false)
    }

    private var lockedOverlay: some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(tokens.accentPrimary)
            Text("meter.locked.title")
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(tokens.contentPrimary)
            Text("meter.locked.message")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(tokens.contentSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton("common.done", tokens: tokens) { dismiss() }
                .padding(.horizontal, Spacing.xl)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(tokens.backgroundPrimary.opacity(0.97))
    }

    private func timeString(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
