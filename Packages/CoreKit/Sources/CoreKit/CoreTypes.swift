import Foundation

/// Travel mode selected at trip creation. Drives game filtering, milestone
/// pacing, and quiet mode (§1.4). Trains behave like a hybrid: window-spotting
/// works (like car) but there is no driver and Quiet Mode defaults on
/// (like plane — shared public space).
public enum TravelMode: String, Codable, CaseIterable, Sendable {
    case car
    case plane
    case train

    /// SF Symbol used wherever the trip's mode is shown.
    public var systemImage: String {
        switch self {
        case .car: return "car.fill"
        case .plane: return "airplane"
        case .train: return "train.side.front.car"
        }
    }

    /// Whether one traveler must be marked as driver (§1.2) — car only.
    public var requiresDriver: Bool { self == .car }

    /// Shared public space → Quiet Mode defaults on (§1.4).
    public var defaultsToQuietMode: Bool { self != .car }
}

/// Age bands used for content selection and game recommendation (§1.5).
public enum AgeBand: Int, Codable, CaseIterable, Comparable, Sendable {
    case preschool = 0 // 3–5
    case early = 1     // 6–8
    case tween = 2     // 9–12
    case teen = 3      // 13+
    case adult = 4

    public static func < (lhs: AgeBand, rhs: AgeBand) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public init(age: Int) {
        switch age {
        case ..<6: self = .preschool
        case 6...8: self = .early
        case 9...12: self = .tween
        case 13...17: self = .teen
        default: self = .adult
        }
    }
}

/// Trip lifecycle states (§2.2). Transitions are validated by
/// `TripStateMachine` in TripKit.
public enum TripStatus: String, Codable, CaseIterable, Sendable {
    case scheduled
    case active
    case paused
    case completed
}

/// Rough trip length estimate captured at onboarding; spaces milestone missions.
public enum TripLength: String, Codable, CaseIterable, Sendable {
    case short   // <1h
    case medium  // 1–3h
    case long    // 3h+
}
