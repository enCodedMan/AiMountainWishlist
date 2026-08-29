import Foundation

/// The ten user-facing life categories from the product constitution, plus
/// `general` — an internal, non-browsable category reserved for
/// cross-category / secret achievements (e.g. "complete an achievement in
/// every category"). See domain-model.md §2.
///
/// `general` must never be shown as a browsable category in discovery UI —
/// that's a presentation rule for `ux-ui-designer`, but the invariant it
/// protects lives here: every XP-earning event has exactly one category, so
/// overall XP always equals the sum of per-category XP (§3.3).
public enum Category: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case fitness
    case adventure
    case travel
    case money
    case career
    case education
    case skills
    case relationships
    case makerProjects
    case experiences
    case general

    /// The six categories with curated built-in seed content at MVP
    /// (domain-model.md §2). The remaining categories are defined but empty
    /// — users can still create their own achievements in them.
    public static let seededAtMVP: Set<Category> = [
        .fitness, .adventure, .travel, .education, .skills, .experiences
    ]

    /// `true` for the ten user-facing browsable categories; `false` only
    /// for `general`, which is an internal bookkeeping category and must
    /// never appear in browse/discovery surfaces.
    public var isBrowsable: Bool {
        self != .general
    }
}
