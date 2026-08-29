import Foundation

/// The three-way choice a blocked cap attempt must present, per
/// domain-model.md §6. The exact screen/interaction design belongs to
/// `ux-ui-designer`; this package only guarantees the underlying rule:
/// block, require one explicit choice, never silently drop an existing
/// quest, never offer a paid way around the cap.
public enum QuestSlotCapChoice: Equatable, Sendable {
    /// Demote one existing quest currently occupying the capped slot type
    /// (to a different slot type or to the backlog), freeing a slot for
    /// the new one. The UI picks the destination; this rule only requires
    /// that a slot be freed by an explicit user choice.
    case demoteExistingQuest

    /// Add the new quest at a different, non-full slot type instead
    /// (e.g. add as a Side Quest instead of Main). Only offered when a
    /// lower active tier exists and has room.
    case addAsDifferentSlotType(QuestSlotType)

    /// Leave everything as it is; the new quest is not activated.
    case cancel
}

/// Returned when an activation attempt would exceed the Main (3) or Side
/// (5) cap.
public struct QuestSlotCapBlock: Equatable, Sendable {
    public let attemptedSlotType: QuestSlotType
    public let cap: Int
    /// IDs of the `UserAchievementInstance`s currently occupying the
    /// capped slot type, so the UI can render them for the "demote one of
    /// these" choice.
    public let currentOccupantInstanceIds: [UUID]
    public let choices: [QuestSlotCapChoice]
}

public enum QuestSlotActivationResult: Equatable, Sendable {
    case allowed
    case blocked(QuestSlotCapBlock)
}

/// Enforces the hard quest-slot caps from domain-model.md §6: 3 concurrent
/// Main Quests, 5 concurrent Side Quests, unlimited Backlog. Paused
/// quests are exempt from both caps by construction — see
/// `activeSlotCounts(from:)`, which only counts instances whose `state`
/// is `.active`.
public enum QuestSlotPolicy {
    public static let mainQuestCap = 3
    public static let sideQuestCap = 5

    /// Counts current Main/Side occupancy from a set of instances,
    /// counting only `.active` instances. `.paused` instances are
    /// excluded even if their `questSlotType` is `.main`/`.side` — this
    /// is what makes pausing a real, guilt-free "take a break" mechanic
    /// rather than a permanent slot loss (§1.4, §6).
    public static func activeSlotCounts(
        from instances: [UserAchievementInstance]
    ) -> (main: Int, side: Int) {
        var main = 0
        var side = 0
        for instance in instances where instance.state == .active {
            switch instance.questSlotType {
            case .main: main += 1
            case .side: side += 1
            case .none: break
            }
        }
        return (main, side)
    }

    /// Evaluates whether activating a new (or resuming a paused) quest
    /// into `slotType` is allowed given current occupancy. Used both for
    /// a fresh `.activate` transition and for `.resume`, per §6's note
    /// that resume re-checks caps at resume time using the instance's
    /// retained `questSlotType`.
    public static func evaluateActivation(
        slotType: QuestSlotType,
        currentActiveMainCount: Int,
        currentActiveSideCount: Int,
        currentMainOccupantInstanceIds: [UUID] = [],
        currentSideOccupantInstanceIds: [UUID] = []
    ) -> QuestSlotActivationResult {
        switch slotType {
        case .none:
            // Not an active-quest slot; nothing to cap.
            return .allowed

        case .main:
            guard currentActiveMainCount >= mainQuestCap else { return .allowed }
            let sideHasRoom = currentActiveSideCount < sideQuestCap
            var choices: [QuestSlotCapChoice] = [.demoteExistingQuest]
            if sideHasRoom {
                choices.append(.addAsDifferentSlotType(.side))
            }
            choices.append(.cancel)
            return .blocked(
                QuestSlotCapBlock(
                    attemptedSlotType: .main,
                    cap: mainQuestCap,
                    currentOccupantInstanceIds: currentMainOccupantInstanceIds,
                    choices: choices
                )
            )

        case .side:
            guard currentActiveSideCount >= sideQuestCap else { return .allowed }
            return .blocked(
                QuestSlotCapBlock(
                    attemptedSlotType: .side,
                    cap: sideQuestCap,
                    currentOccupantInstanceIds: currentSideOccupantInstanceIds,
                    choices: [.demoteExistingQuest, .cancel]
                )
            )
        }
    }
}
