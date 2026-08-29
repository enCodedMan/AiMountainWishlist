import Foundation

/// How a completed achievement's truthfulness was established.
/// Defaults to `.selfReported` at completion time (trust-first per
/// PD-002 / domain-model.md §1.2).
public enum VerificationLevel: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case selfReported
    case evidence
    case verified
}

/// Which active-quest track (if any) a `UserAchievementInstance` occupies.
/// Only meaningful while `state ∈ {.active, .paused}` — see domain-model.md §6.
public enum QuestSlotType: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case none
    case main
    case side
}

/// Designer-assigned placeholder rarity for seed content (domain-model.md
/// §5). Never presented to end users as a statistic — only real computed
/// rarity (a backend aggregate, not modeled in this package) may claim
/// that. See `RaritySwitchover` for the threshold rule that supersedes
/// this label once real completion data exists.
public enum RarityLabel: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
}

/// Spec (domain-model.md §5): once an achievement has been completed by at
/// least this many distinct users, computed rarity replaces the
/// provisional label for that achievement everywhere it's shown. Below the
/// threshold, fall back to `provisionalRarity`. This constant exists now so
/// the switchover activates automatically as usage grows, without a
/// follow-up migration or code change.
public enum RaritySwitchover {
    public static let minimumDistinctCompletions = 30

    /// `true` once computed rarity (a backend aggregate not modeled by this
    /// package) should be shown instead of `provisionalRarity`.
    public static func shouldUseComputedRarity(distinctCompletionCount: Int) -> Bool {
        distinctCompletionCount >= minimumDistinctCompletions
    }
}
