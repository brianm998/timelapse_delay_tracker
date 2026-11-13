import Foundation

/// The arithmetic behind the results card, kept out of the view so it can be unit tested.
enum ShotCalculator {
    /// How many frames the rig shoots before the move starts, or nil when there is nothing to
    /// compute (no valid interval, or the start time has passed).
    static func preMoveShots(interval: Double, secondsUntilStart: Double) -> Double? {
        guard interval > 0, secondsUntilStart > 0 else { return nil }
        return secondsUntilStart / interval
    }

    /// The whole number to enter into the rig: always rounded up, so the move never starts early.
    static func rigShotCount(_ shots: Double) -> Int {
        Int(shots.rounded(.up))
    }
}
