import Foundation

/// Abstraction over StoreKit 2 entitlements so game-gating logic is testable.
/// The production implementation (Stage 1, paywall feature branch) reads
/// `Transaction.currentEntitlements`.
public protocol EntitlementProviding: Sendable {
    func isSubscriber() async -> Bool
}

/// Pure gate decision checked before each game start and on heartbeat (§6).
public enum PaywallGate {
    public static func canPlay(meterState: MeterState) -> Bool {
        meterState != .locked
    }
}

/// Parental gate challenge (§7 spec): simple math, 3-attempt lockout handled
/// by the presenting view model.
public struct ParentalGateChallenge: Sendable, Equatable {
    public let question: String
    public let answer: Int

    public init(question: String, answer: Int) {
        self.question = question
        self.answer = answer
    }

    public static func make(using generator: inout some RandomNumberGenerator) -> ParentalGateChallenge {
        let a = Int.random(in: 3...9, using: &generator)
        let b = Int.random(in: 3...9, using: &generator)
        return ParentalGateChallenge(question: "\(a) × \(b)", answer: a * b)
    }
}
