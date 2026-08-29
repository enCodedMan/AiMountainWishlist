import Foundation

/// One immutable row per XP grant or reversal. Never mutated after
/// creation — a reversal is a **new** compensating entry (negative
/// amount, referencing the original via `reversalOfEntryId`), not an
/// edit to the original row. This is what "append-only" means per
/// domain-model.md §3.4: the ledger is a true event log, so lifetime
/// totals stay auditable and a completion can be undone without ever
/// updating history.
public struct XPLedgerEntry: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let category: Category
    /// Positive for a grant, negative for a reversal. Never zero.
    public let amount: Int
    public let achievementDefinitionId: UUID?
    public let userAchievementInstanceId: UUID?
    public let grantedAt: Date
    /// Set only on a reversal entry; points at the original grant entry
    /// it reverses.
    public let reversalOfEntryId: UUID?

    public init(
        id: UUID,
        userId: UUID,
        category: Category,
        amount: Int,
        achievementDefinitionId: UUID?,
        userAchievementInstanceId: UUID?,
        grantedAt: Date,
        reversalOfEntryId: UUID? = nil
    ) {
        self.id = id
        self.userId = userId
        self.category = category
        self.amount = amount
        self.achievementDefinitionId = achievementDefinitionId
        self.userAchievementInstanceId = userAchievementInstanceId
        self.grantedAt = grantedAt
        self.reversalOfEntryId = reversalOfEntryId
    }

    public var isReversal: Bool {
        reversalOfEntryId != nil
    }
}

public enum XPLedgerError: Error, Equatable {
    case entryNotFound(UUID)
    case entryAlreadyReversed(UUID)
    case cannotReverseAReversalEntry(UUID)
}

/// An append-only per-user/per-app XP ledger. Grants and reversals are
/// both represented as immutable rows; nothing is ever updated or
/// deleted. This type is an in-memory reference model of the ledger
/// semantics — the real store is `xp_ledger` in Postgres (see the backend
/// migration), which follows the identical insert-only rule enforced here.
public struct XPLedger: Equatable, Sendable {
    public private(set) var entries: [XPLedgerEntry] = []

    public init(entries: [XPLedgerEntry] = []) {
        self.entries = entries
    }

    /// Grants XP by appending a new entry. Returns the created entry so
    /// the caller can store its `id` on the `UserAchievementInstance`
    /// (`xpLedgerEntryId`) for later reversal.
    @discardableResult
    public mutating func grant(
        id: UUID = UUID(),
        userId: UUID,
        category: Category,
        amount: Int,
        achievementDefinitionId: UUID? = nil,
        userAchievementInstanceId: UUID? = nil,
        at date: Date = Date()
    ) -> XPLedgerEntry {
        precondition(amount > 0, "Grants must be positive; use reverse(entryId:) to remove XP.")
        let entry = XPLedgerEntry(
            id: id,
            userId: userId,
            category: category,
            amount: amount,
            achievementDefinitionId: achievementDefinitionId,
            userAchievementInstanceId: userAchievementInstanceId,
            grantedAt: date
        )
        entries.append(entry)
        return entry
    }

    /// Reverses exactly one entry by ID, appending a compensating
    /// negative entry. Does not touch any other entry. Reversing the same
    /// entry twice, or reversing a reversal, is rejected.
    @discardableResult
    public mutating func reverse(
        entryId: UUID,
        reversalId: UUID = UUID(),
        at date: Date = Date()
    ) throws -> XPLedgerEntry {
        guard let original = entries.first(where: { $0.id == entryId }) else {
            throw XPLedgerError.entryNotFound(entryId)
        }
        if original.isReversal {
            throw XPLedgerError.cannotReverseAReversalEntry(entryId)
        }
        let alreadyReversed = entries.contains { $0.reversalOfEntryId == entryId }
        if alreadyReversed {
            throw XPLedgerError.entryAlreadyReversed(entryId)
        }
        let reversal = XPLedgerEntry(
            id: reversalId,
            userId: original.userId,
            category: original.category,
            amount: -original.amount,
            achievementDefinitionId: original.achievementDefinitionId,
            userAchievementInstanceId: original.userAchievementInstanceId,
            grantedAt: date,
            reversalOfEntryId: original.id
        )
        entries.append(reversal)
        return reversal
    }

    /// Net lifetime XP for a user across every category.
    public func totalXP(userId: UUID) -> Int {
        entries.filter { $0.userId == userId }.reduce(0) { $0 + $1.amount }
    }

    /// Net lifetime XP for a user within one category.
    public func totalXP(userId: UUID, category: Category) -> Int {
        entries
            .filter { $0.userId == userId && $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
}
