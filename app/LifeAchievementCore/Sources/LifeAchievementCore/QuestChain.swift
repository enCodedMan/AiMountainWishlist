import Foundation

/// Chain-level metadata: a quest chain's own display name and description
/// (e.g. "5K Questline"), as distinct from `QuestChainRung`, which is a
/// single achievement's position *within* a chain. Nothing previously
/// stored this — `AchievementDefinition.questChainId` was just a bare
/// grouping UUID shared by a chain's rungs — but the achievement-detail
/// screen (docs/wireframes.md) needs it to render "Part of the 5K
/// Questline · Step 3 of 6." See docs/domain-model.md §4.
///
/// Metadata only: this type carries no progression logic. Chain-completion
/// behavior (auto-surfacing the next rung, auto-completing lower ones) is
/// entirely in `QuestChain.completing(...)` below and is unaffected by
/// this type.
public struct QuestChainDefinition: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var description: String
    /// A chain lives in exactly one category, matching all of its rungs'
    /// `AchievementDefinition.category`.
    public var category: Category

    public init(id: UUID, name: String, description: String, category: Category) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
    }
}

/// A lightweight, chain-scoped view of one rung — just the fields the
/// chain-progression rules in domain-model.md §4.4 need. Callers project
/// their `AchievementDefinition`s into this shape (or use
/// `QuestChainRung.init(from:)` below) rather than this package depending
/// on any persistence/repository type.
public struct QuestChainRung: Identifiable, Equatable, Sendable {
    public var id: UUID { achievementDefinitionId }
    public let achievementDefinitionId: UUID
    public let questChainId: UUID
    /// 1-indexed position within the chain.
    public let position: Int

    public init(achievementDefinitionId: UUID, questChainId: UUID, position: Int) {
        precondition(position >= 1, "Quest chain rung position is 1-indexed.")
        self.achievementDefinitionId = achievementDefinitionId
        self.questChainId = questChainId
        self.position = position
    }

    public init?(from definition: AchievementDefinition) {
        guard let questChainId = definition.questChainId,
              let position = definition.questChainPosition else {
            return nil
        }
        self.init(achievementDefinitionId: definition.id, questChainId: questChainId, position: position)
    }
}

/// What completing one rung should do to the rest of its chain, per
/// domain-model.md §4.4:
/// - Completing rung N surfaces rung N+1 as `.discovered` — **never**
///   auto-`.active` (would risk silently exceeding quest-slot caps or
///   overriding something the user would rather pursue).
/// - Completing a higher rung retroactively auto-completes lower rungs
///   that aren't already completed, rather than leaving a confusing gap
///   or forcing the user to backfill trivial steps they've clearly
///   already cleared.
public struct QuestChainCompletionEffect: Equatable {
    /// Lower rungs (position < the completed rung's position) that were
    /// not already `.completed`, in ascending position order. The caller
    /// should transition each of these to `.completed` and grant its XP,
    /// exactly as if the user had completed it directly.
    public let rungsToAutoComplete: [QuestChainRung]

    /// The next rung (position + 1), if one exists in the chain and it is
    /// currently at the implicit `.notDiscovered` state (no instance, or
    /// an instance whose state is `.notDiscovered`). `nil` if this was the
    /// last rung, or if the next rung already has a real instance (never
    /// downgrade a rung the user has already engaged with).
    public let rungToDiscover: QuestChainRung?
}

public enum QuestChain {
    /// Computes the chain-wide effects of completing `rung`, given every
    /// other rung in the same chain and each rung's current state
    /// (defaulting to `.notDiscovered` for any rung with no instance row
    /// yet, consistent with the implicit-state rule in §1.4).
    ///
    /// Pure function: this package has no persistence, so it returns
    /// instructions for the caller (the sync/repository layer) to apply —
    /// which rungs to mark completed (with XP granted via `XPLedger`,
    /// same as any other completion) and which single rung, if any, to
    /// surface as newly `.discovered`.
    public static func completing(
        rung: QuestChainRung,
        chainRungs: [QuestChainRung],
        currentStates: [UUID: AchievementState]
    ) -> QuestChainCompletionEffect {
        precondition(
            chainRungs.allSatisfy { $0.questChainId == rung.questChainId },
            "All rungs passed to completing(rung:chainRungs:currentStates:) must belong to the same chain."
        )

        func state(of r: QuestChainRung) -> AchievementState {
            currentStates[r.achievementDefinitionId] ?? .notDiscovered
        }

        let lowerRungsNotYetCompleted = chainRungs
            .filter { $0.position < rung.position && state(of: $0) != .completed }
            .sorted { $0.position < $1.position }

        let nextRung = chainRungs.first { $0.position == rung.position + 1 }
        let rungToDiscover: QuestChainRung? = {
            guard let nextRung else { return nil }
            return state(of: nextRung) == .notDiscovered ? nextRung : nil
        }()

        return QuestChainCompletionEffect(
            rungsToAutoComplete: lowerRungsNotYetCompleted,
            rungToDiscover: rungToDiscover
        )
    }
}
