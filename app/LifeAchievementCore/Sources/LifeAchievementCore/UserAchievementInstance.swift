import Foundation

/// One row per (user, achievement definition) pair, created lazily —
/// domain-model.md §0 / §1.2. Holds the state-machine state, verification
/// level actually achieved, quest-slot assignment, and timestamps.
///
/// Important: `AchievementState.notDiscovered` has **no** row of this
/// type. It's the implicit default for any catalog item with no instance
/// yet for a given user. Do not create a row per user per catalog item
/// up front — create it the moment a real discovery event happens. The
/// static factories below (`discovered`, `userCreated`,
/// `integrationVerifiedCompletion`) construct the first row for each of
/// the entry paths the domain model calls out explicitly (§1.4).
public struct UserAchievementInstance: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var userId: UUID
    public var achievementDefinitionId: UUID
    public var state: AchievementState
    /// Meaningful only while `state ∈ {.active, .paused}` — see §6.
    public var questSlotType: QuestSlotType
    /// Set at completion time; defaults to `.selfReported`.
    public var verificationLevel: VerificationLevel
    /// A Storage reference (e.g. photo), populated when
    /// `verificationLevel == .evidence`.
    public var evidenceRef: String?
    /// Current measured progress toward `completionCriteria.targetValue`,
    /// for `.cumulativeCount`/`.thresholdRecord` types. Nil for `.binary`.
    public var progressValue: Double?
    /// Pure visibility toggle — never affects XP or state. This is what
    /// "hide from profile" means (§1.4): the achievement stays permanently
    /// in the user's private history with its XP intact, it just doesn't
    /// render on the public profile/trophy case.
    public var isHiddenFromProfile: Bool
    public var discoveredAt: Date?
    public var activatedAt: Date?
    public var completedAt: Date?
    /// Points at the XP ledger entry that granted XP for this completion,
    /// so an undo can find and reverse exactly one entry. Nil unless
    /// `state == .completed` (or was, before an undo).
    public var xpLedgerEntryId: UUID?

    public init(
        id: UUID,
        userId: UUID,
        achievementDefinitionId: UUID,
        state: AchievementState,
        questSlotType: QuestSlotType = .none,
        verificationLevel: VerificationLevel = .selfReported,
        evidenceRef: String? = nil,
        progressValue: Double? = nil,
        isHiddenFromProfile: Bool = false,
        discoveredAt: Date? = nil,
        activatedAt: Date? = nil,
        completedAt: Date? = nil,
        xpLedgerEntryId: UUID? = nil
    ) {
        self.id = id
        self.userId = userId
        self.achievementDefinitionId = achievementDefinitionId
        self.state = state
        self.questSlotType = questSlotType
        self.verificationLevel = verificationLevel
        self.evidenceRef = evidenceRef
        self.progressValue = progressValue
        self.isHiddenFromProfile = isHiddenFromProfile
        self.discoveredAt = discoveredAt
        self.activatedAt = activatedAt
        self.completedAt = completedAt
        self.xpLedgerEntryId = xpLedgerEntryId
    }

    // MARK: - Entry-point factories (domain-model.md §1.4 "special-cased non-linear transitions")

    /// The ordinary discovery path: detail view opened, surfaced in
    /// onboarding, or a recommendation is shown. Creates the row in
    /// `.discovered`.
    public static func discovered(
        id: UUID = UUID(),
        userId: UUID,
        achievementDefinitionId: UUID,
        at date: Date = Date()
    ) -> UserAchievementInstance {
        UserAchievementInstance(
            id: id,
            userId: userId,
            achievementDefinitionId: achievementDefinitionId,
            state: .discovered,
            discoveredAt: date
        )
    }

    /// A user-created achievement never passes through `.notDiscovered` or
    /// `.discovered` for its creator — creation writes directly into
    /// `.interested` or `.active`, the creator's choice at creation time.
    public enum UserCreatedStartingState: Equatable, Sendable {
        case interested
        case active
    }

    public static func userCreated(
        id: UUID = UUID(),
        userId: UUID,
        achievementDefinitionId: UUID,
        startingAs: UserCreatedStartingState,
        questSlotType: QuestSlotType = .none,
        at date: Date = Date()
    ) -> UserAchievementInstance {
        let state: AchievementState = (startingAs == .interested) ? .interested : .active
        return UserAchievementInstance(
            id: id,
            userId: userId,
            achievementDefinitionId: achievementDefinitionId,
            state: state,
            questSlotType: state == .active ? questSlotType : .none,
            discoveredAt: date,
            activatedAt: state == .active ? date : nil
        )
    }

    /// AI-generated achievements (future) are created directly into
    /// `.discovered` for the target user — they're a suggestion, not yet
    /// chosen. Functionally identical to `discovered(...)`; kept as a
    /// distinct named factory for call-site clarity about intent/source.
    public static func aiGenerated(
        id: UUID = UUID(),
        userId: UUID,
        achievementDefinitionId: UUID,
        at date: Date = Date()
    ) -> UserAchievementInstance {
        discovered(id: id, userId: userId, achievementDefinitionId: achievementDefinitionId, at: date)
    }

    /// Integration-detected achievements (future — Strava, Health) can go
    /// straight from implicit `.notDiscovered` to `.completed` in one
    /// step, skipping `.discovered`/`.interested`/`.active` entirely, with
    /// `verificationLevel` set to `.verified` automatically.
    public static func integrationVerifiedCompletion(
        id: UUID = UUID(),
        userId: UUID,
        achievementDefinitionId: UUID,
        xpLedgerEntryId: UUID,
        at date: Date = Date()
    ) -> UserAchievementInstance {
        UserAchievementInstance(
            id: id,
            userId: userId,
            achievementDefinitionId: achievementDefinitionId,
            state: .completed,
            verificationLevel: .verified,
            completedAt: date,
            xpLedgerEntryId: xpLedgerEntryId
        )
    }
}
