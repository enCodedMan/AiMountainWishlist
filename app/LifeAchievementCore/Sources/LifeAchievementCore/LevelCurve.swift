import Foundation

/// The XP -> level curve from domain-model.md §3.3. **One formula, used
/// identically for overall level and every category level** — "Level"
/// means the same math everywhere, which is what makes category levels
/// legible as a character sheet.
///
/// `cumulative(L) = 25 × (L − 1) × (L + 2)`, level 1 = 0 XP floor.
/// Equivalently, the cost to go from level L to L+1 is `50 × (L+1)` — each
/// level costs 50 more XP than the last. This curve is a calibrated
/// starting guess (see domain-model.md §7), not settled truth.
public enum LevelCurve {
    /// Cumulative XP required to **reach** `level`. `level` must be >= 1.
    public static func cumulativeXP(forLevel level: Int) -> Int {
        precondition(level >= 1, "Level must be >= 1.")
        return 25 * (level - 1) * (level + 2)
    }

    /// The inverse of `cumulativeXP(forLevel:)`: the level reached by a
    /// given amount of cumulative XP (the largest `L` such that
    /// `cumulativeXP(forLevel: L) <= xp`). `xp` must be >= 0.
    ///
    /// Implemented as an exact integer binary search (rather than solving
    /// the quadratic with floating point) so results are deterministic
    /// and exact at any XP magnitude, including values far beyond the
    /// hand-authored table in §3.3.
    public static func level(forCumulativeXP xp: Int) -> Int {
        precondition(xp >= 0, "Cumulative XP must be >= 0.")

        var low = 1
        var high = 1
        while cumulativeXP(forLevel: high + 1) <= xp {
            high *= 2
        }

        while low < high {
            let mid = low + (high - low + 1) / 2
            if cumulativeXP(forLevel: mid) <= xp {
                low = mid
            } else {
                high = mid - 1
            }
        }
        return low
    }

    /// XP still needed, from `xp`, to reach `xp`'s next level. Convenience
    /// for progress-bar UI; not part of the core formula itself.
    public static func xpRemainingToNextLevel(currentCumulativeXP xp: Int) -> Int {
        let currentLevel = level(forCumulativeXP: xp)
        return cumulativeXP(forLevel: currentLevel + 1) - xp
    }
}
