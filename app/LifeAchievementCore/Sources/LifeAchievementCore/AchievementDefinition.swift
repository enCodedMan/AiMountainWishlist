import Foundation

/// The XP band table from domain-model.md §3.1. Built-in achievement XP
/// values must always be one of these discrete numbers — never an
/// arbitrary per-item number — to keep the scale legible and prevent slow,
/// unnoticed inflation as more content gets added by different people.
public enum XPBand: CaseIterable, Sendable {
    case small
    case moderate
    case major
    case exceptional

    /// The discrete values allowed within this band.
    public var allowedValues: [Int] {
        switch self {
        case .small: return [10, 15, 20, 25, 30, 40, 50]
        case .moderate: return [100, 150, 200, 250, 300, 400, 500]
        case .major: return [500, 750, 1000, 1500, 2000, 2500]
        case .exceptional: return [2500, 5000, 7500, 10000]
        }
    }

    /// All discrete values allowed across every band, for validating an
    /// arbitrary `xpValue`.
    public static var allAllowedValues: Set<Int> {
        Set(XPBand.allCases.flatMap { $0.allowedValues })
    }

    /// `true` if `value` is one of the fixed discrete numbers in §3.1.
    public static func isValidBuiltInXPValue(_ value: Int) -> Bool {
        allAllowedValues.contains(value)
    }

    /// The Exceptional band (2,500–10,000+) is reserved for built-in/
    /// AI-vetted content only in v0.1 — a user cannot self-assign
    /// Exceptional XP to their own creation (domain-model.md §3.4, the
    /// single highest-leverage anti-abuse safeguard called out in the
    /// spec). Major (500–2,500) is the ceiling for user-created content.
    public static func isValidUserCreatedXPValue(_ value: Int) -> Bool {
        (XPBand.small.allowedValues + XPBand.moderate.allowedValues + XPBand.major.allowedValues)
            .contains(value)
    }
}

/// The catalog entry for an achievement. One row exists regardless of how
/// many users have seen or completed it. See domain-model.md §0 and §1.1
/// for why this is split from `UserAchievementInstance`: verification
/// level and state are properties of a user's *relationship* to an
/// achievement, not the achievement itself.
public struct AchievementDefinition: Identifiable, Equatable, Codable, Sendable {
    /// Where an achievement definition originated.
    public enum Source: String, Codable, Equatable, Hashable, CaseIterable, Sendable {
        case builtIn
        case userCreated
        case aiGenerated
        case integrationDetected
    }

    public let id: UUID
    public var name: String
    /// Exactly one primary category. No multi-category tagging in v0.1.
    public var category: Category
    public var description: String
    public var completionCriteria: CompletionCriteria
    /// Must be one of `XPBand.allAllowedValues` — see `XPBand`.
    public var xpValue: Int
    /// Null if this achievement is not part of a quest chain.
    public var questChainId: UUID?
    /// 1-indexed rung position within the chain. Null if standalone.
    public var questChainPosition: Int?
    /// Design-time-only placeholder for seed content (§5). Null for
    /// user-created achievements — they don't get a curated rarity guess.
    /// Never confused with computed rarity, a separate backend aggregate.
    public var provisionalRarity: RarityLabel?
    /// If true, name/description/criteria are hidden from browse/discovery
    /// until unlocked or nearly met. Presentation is `ux-ui-designer`'s
    /// concern; the flag itself lives here.
    public var isSecret: Bool
    public var source: Source
    /// Set for `.userCreated`; null otherwise. Determines who can edit or
    /// delete the definition.
    public var creatorUserId: UUID?
    public var createdAt: Date

    public init(
        id: UUID,
        name: String,
        category: Category,
        description: String,
        completionCriteria: CompletionCriteria,
        xpValue: Int,
        questChainId: UUID? = nil,
        questChainPosition: Int? = nil,
        provisionalRarity: RarityLabel? = nil,
        isSecret: Bool = false,
        source: Source,
        creatorUserId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.completionCriteria = completionCriteria
        self.xpValue = xpValue
        self.questChainId = questChainId
        self.questChainPosition = questChainPosition
        self.provisionalRarity = provisionalRarity
        self.isSecret = isSecret
        self.source = source
        self.creatorUserId = creatorUserId
        self.createdAt = createdAt
    }

    /// `true` if this achievement is a rung in a quest chain.
    public var isQuestChainRung: Bool {
        questChainId != nil
    }
}
