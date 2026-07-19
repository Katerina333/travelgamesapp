import SwiftUI

/// 4-pt spacing grid (§5.2).
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
    public static let xl: CGFloat = 32
}

/// Corner radius tokens (§5.2).
public enum Radius {
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
}

/// Minimum tap target for kid-friendly UI (§5.3).
public enum TapTarget {
    public static let minimum: CGFloat = 44
}
