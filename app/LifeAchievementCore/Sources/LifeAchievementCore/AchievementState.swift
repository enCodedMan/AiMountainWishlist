import Foundation

/// The seven achievement states from domain-model.md §1.4.
///
/// `.notDiscovered` has no database row — it's the implicit default for
/// any catalog item with no `UserAchievementInstance` yet for a given
/// user. It exists here purely so the state machine below has a starting
/// state to validate transitions from/to.
public enum AchievementState: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
    case notDiscovered
    case discovered
    case interested
    case active
    case completed
    case paused
    case abandoned
}

/// The user action that drives a state transition. Named at the level of
/// intent (what the user/system is doing), not at the level of every
/// distinct button copy in the table — several table rows describe the
/// same underlying action reached from different starting states (e.g.
/// "Start directly," "commit from backlog," and "restart" are all
/// `.activate`; slot-cap checking applies identically to all of them).
/// `.resume` is kept distinct from `.activate` even though both land on
/// `.active`, because resuming a paused quest is semantically "continue
/// what you retained" rather than "begin," per §1.4/§6's separate
/// resume-time cap re-check note.
public enum AchievementTransitionTrigger: String, Equatable, Hashable, CaseIterable, Sendable {
    /// notDiscovered -> discovered: detail view opened, shown in
    /// onboarding, or a recommendation is surfaced.
    case discover

    /// discovered -> interested: "Want to do" / save to backlog.
    case saveToBacklog

    /// {discovered, interested, abandoned} -> active: "Start," commit
    /// from backlog, or restart. Subject to quest-slot caps (§6).
    case activate

    /// paused -> active: resume. Quest-slot caps are re-checked at resume
    /// time using the instance's retained `questSlotType` (§6).
    case resume

    /// {discovered, interested, active, paused} -> completed: mark done.
    /// Grants XP immediately (except from `.active`/`.paused`, XP is
    /// granted the same way — see `XPLedger`).
    case markCompleted

    /// {discovered, interested, active, paused} -> abandoned: "Not
    /// interested" (discovered/interested) or "stop pursuing" / "give up"
    /// (active/paused). One state, several entry triggers, per §1.4 —
    /// reversible and non-punitive regardless of entry point. UI copy for
    /// this trigger from `.discovered`/`.interested` should read "Not for
    /// me" / "Hide," never the word "Abandoned" (§1.4 note) — that's a
    /// presentation concern, not an engine one.
    case abandon

    /// active -> paused: frees the quest slot immediately. Paused quests
    /// never count against the 3/5 caps (§6).
    case pause

    /// active -> interested: demote back to backlog without fully
    /// abandoning. Frees the quest slot.
    case demoteToBacklog

    /// abandoned -> interested: reconsider ("maybe someday"). Fully
    /// reversible.
    case reconsider

    /// completed -> discovered: explicit "Undo completion" only. A
    /// correction path ("I marked this by mistake"), not gameplay. Lands
    /// at `.discovered`, not `.active` — undoing a mistaken completion
    /// means "this didn't happen," not "I'm now pursuing it." Callers are
    /// responsible for reversing the XP ledger entry referenced by
    /// `xpLedgerEntryId` when applying this transition — see `XPLedger`.
    case undoCompletion
}

/// Thrown/returned when a requested (from-state, trigger) pair is not in
/// the transition table — i.e. an illegal transition, such as
/// `.completed -> .active` directly.
public struct IllegalAchievementTransition: Error, Equatable {
    public let from: AchievementState
    public let trigger: AchievementTransitionTrigger

    public init(from: AchievementState, trigger: AchievementTransitionTrigger) {
        self.from = from
        self.trigger = trigger
    }
}

/// Validates and executes transitions against the exact table in
/// domain-model.md §1.4. This is real enforced logic, not
/// documentation-as-comments: any (from, trigger) pair not present in
/// `transitionTable` is rejected.
public enum AchievementStateMachine {
    /// The full transition table from §1.4, keyed by (from-state,
    /// trigger) -> to-state. Every row in the spec's table is represented
    /// exactly once here (18 legal transitions).
    public static let transitionTable: [AchievementState: [AchievementTransitionTrigger: AchievementState]] = [
        .notDiscovered: [
            .discover: .discovered
        ],
        .discovered: [
            .saveToBacklog: .interested,
            .activate: .active,
            .markCompleted: .completed,
            .abandon: .abandoned
        ],
        .interested: [
            .activate: .active,
            .abandon: .abandoned,
            .markCompleted: .completed
        ],
        .active: [
            .markCompleted: .completed,
            .pause: .paused,
            .abandon: .abandoned,
            .demoteToBacklog: .interested
        ],
        .paused: [
            .resume: .active,
            .abandon: .abandoned,
            .markCompleted: .completed
        ],
        .abandoned: [
            .reconsider: .interested,
            .activate: .active
        ],
        .completed: [
            .undoCompletion: .discovered
        ]
    ]

    /// `true` if this exact (from, trigger) pair is legal.
    public static func canTransition(from: AchievementState, trigger: AchievementTransitionTrigger) -> Bool {
        transitionTable[from]?[trigger] != nil
    }

    /// Validates the transition and returns the resulting state, or
    /// throws `IllegalAchievementTransition` if the (from, trigger) pair
    /// isn't in the table.
    @discardableResult
    public static func transition(
        from: AchievementState,
        trigger: AchievementTransitionTrigger
    ) throws -> AchievementState {
        guard let to = transitionTable[from]?[trigger] else {
            throw IllegalAchievementTransition(from: from, trigger: trigger)
        }
        return to
    }
}
