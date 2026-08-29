import XCTest
@testable import LifeAchievementCore

final class QuestChainTests: XCTestCase {

    // Six-rung "Peak Bagging" style chain (domain-model.md §4.1).
    private func makeChain() -> (chainId: UUID, rungs: [QuestChainRung]) {
        let chainId = UUID()
        let rungs = (1...6).map { position in
            QuestChainRung(achievementDefinitionId: UUID(), questChainId: chainId, position: position)
        }
        return (chainId, rungs)
    }

    func testCompletingARungSurfacesTheNextRungAsDiscovered() {
        let (_, rungs) = makeChain()
        let states: [UUID: AchievementState] = [:] // everything implicitly .notDiscovered

        let effect = QuestChain.completing(rung: rungs[0], chainRungs: rungs, currentStates: states)

        XCTAssertEqual(effect.rungToDiscover, rungs[1])
        XCTAssertEqual(effect.rungsToAutoComplete, []) // rung 1 has no lower rungs
    }

    func testCompletingTheLastRungHasNoNextRungToDiscover() {
        let (_, rungs) = makeChain()
        let effect = QuestChain.completing(rung: rungs[5], chainRungs: rungs, currentStates: [:])
        XCTAssertNil(effect.rungToDiscover)
    }

    func testNextRungIsNeverAutoActivated() {
        // The effect only ever names a rung to *discover*, never a state
        // to set it to beyond .discovered — enforced by the type itself
        // (QuestChainCompletionEffect.rungToDiscover is a rung to surface,
        // not a state), but assert the discovered rung really is the
        // notDiscovered->discovered case, i.e. it wasn't already engaged.
        let (_, rungs) = makeChain()
        let states: [UUID: AchievementState] = [rungs[1].achievementDefinitionId: .active]

        let effect = QuestChain.completing(rung: rungs[0], chainRungs: rungs, currentStates: states)

        // Rung 2 is already .active (user engaged with it directly) —
        // never downgrade/re-surface it.
        XCTAssertNil(effect.rungToDiscover)
    }

    func testCompletingAHigherRungAutoCompletesUnfinishedLowerRungs() {
        let (_, rungs) = makeChain()
        // User already ran sub-22:30 (rung 4) without ever logging the
        // easier rungs. Rungs 1-3 are in various pre-completion states.
        let states: [UUID: AchievementState] = [
            rungs[0].achievementDefinitionId: .notDiscovered,
            rungs[1].achievementDefinitionId: .interested,
            rungs[2].achievementDefinitionId: .discovered
        ]

        let effect = QuestChain.completing(rung: rungs[3], chainRungs: rungs, currentStates: states)

        XCTAssertEqual(effect.rungsToAutoComplete, [rungs[0], rungs[1], rungs[2]])
        XCTAssertEqual(effect.rungToDiscover, rungs[4])
    }

    func testAlreadyCompletedLowerRungsAreNotReCompleted() {
        let (_, rungs) = makeChain()
        // Rung 2 was already completed earlier; rungs 1 and 3 were not.
        let states: [UUID: AchievementState] = [
            rungs[0].achievementDefinitionId: .discovered,
            rungs[1].achievementDefinitionId: .completed,
            rungs[2].achievementDefinitionId: .active
        ]

        let effect = QuestChain.completing(rung: rungs[3], chainRungs: rungs, currentStates: states)

        // Rung 2 must not appear again — it's already completed, no
        // re-grinding a chain rung for repeat XP (§4.4).
        XCTAssertEqual(effect.rungsToAutoComplete, [rungs[0], rungs[2]])
    }

    func testHigherRungsAreUnaffectedByCompletingALowerRung() {
        let (_, rungs) = makeChain()
        let states: [UUID: AchievementState] = [
            rungs[3].achievementDefinitionId: .active,
            rungs[4].achievementDefinitionId: .notDiscovered
        ]

        let effect = QuestChain.completing(rung: rungs[2], chainRungs: rungs, currentStates: states)

        XCTAssertEqual(effect.rungsToAutoComplete, [rungs[0], rungs[1]])
        XCTAssertEqual(effect.rungToDiscover, rungs[3]) // next rung only, regardless of rung 5's state
    }

    func testQuestChainRungInitFromDefinitionReturnsNilForStandaloneAchievements() {
        let definition = AchievementDefinition(
            id: UUID(),
            name: "Run your first 5K",
            category: .fitness,
            description: "",
            completionCriteria: .binary,
            xpValue: 50,
            source: .builtIn
        )
        XCTAssertNil(QuestChainRung(from: definition))
    }

    func testQuestChainRungInitFromDefinitionSucceedsForChainMembers() throws {
        let chainId = UUID()
        let definition = AchievementDefinition(
            id: UUID(),
            name: "Summit your first 14er",
            category: .adventure,
            description: "",
            completionCriteria: .binary,
            xpValue: 500,
            questChainId: chainId,
            questChainPosition: 4,
            source: .builtIn
        )
        let rung = try XCTUnwrap(QuestChainRung(from: definition))
        XCTAssertEqual(rung.position, 4)
        XCTAssertEqual(rung.questChainId, chainId)
    }
}
