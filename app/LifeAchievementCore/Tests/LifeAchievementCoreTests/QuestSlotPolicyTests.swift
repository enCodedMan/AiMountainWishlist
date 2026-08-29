import XCTest
@testable import LifeAchievementCore

final class QuestSlotPolicyTests: XCTestCase {

    func testFourthMainQuestAttemptIsBlocked() {
        let result = QuestSlotPolicy.evaluateActivation(
            slotType: .main,
            currentActiveMainCount: 3,
            currentActiveSideCount: 1
        )
        guard case .blocked(let block) = result else {
            return XCTFail("Expected .blocked, got \(result)")
        }
        XCTAssertEqual(block.attemptedSlotType, .main)
        XCTAssertEqual(block.cap, 3)
        XCTAssertTrue(block.choices.contains(.demoteExistingQuest))
        XCTAssertTrue(block.choices.contains(.cancel))
        XCTAssertTrue(block.choices.contains(.addAsDifferentSlotType(.side))) // side has room (1 of 5)
    }

    func testFourthMainQuestAttemptDoesNotOfferSideWhenSideIsAlsoFull() {
        let result = QuestSlotPolicy.evaluateActivation(
            slotType: .main,
            currentActiveMainCount: 3,
            currentActiveSideCount: 5
        )
        guard case .blocked(let block) = result else {
            return XCTFail("Expected .blocked, got \(result)")
        }
        XCTAssertFalse(block.choices.contains(.addAsDifferentSlotType(.side)))
    }

    func testThirdMainQuestIsAllowed() {
        let result = QuestSlotPolicy.evaluateActivation(
            slotType: .main,
            currentActiveMainCount: 2,
            currentActiveSideCount: 0
        )
        XCTAssertEqual(result, .allowed)
    }

    func testSixthSideQuestAttemptIsBlocked() {
        let result = QuestSlotPolicy.evaluateActivation(
            slotType: .side,
            currentActiveMainCount: 0,
            currentActiveSideCount: 5
        )
        guard case .blocked(let block) = result else {
            return XCTFail("Expected .blocked, got \(result)")
        }
        XCTAssertEqual(block.attemptedSlotType, .side)
        XCTAssertEqual(block.cap, 5)
        XCTAssertEqual(block.choices, [.demoteExistingQuest, .cancel])
    }

    func testFifthSideQuestIsAllowed() {
        let result = QuestSlotPolicy.evaluateActivation(
            slotType: .side,
            currentActiveMainCount: 0,
            currentActiveSideCount: 4
        )
        XCTAssertEqual(result, .allowed)
    }

    func testNoneSlotTypeIsAlwaysAllowed() {
        let result = QuestSlotPolicy.evaluateActivation(
            slotType: .none,
            currentActiveMainCount: 3,
            currentActiveSideCount: 5
        )
        XCTAssertEqual(result, .allowed)
    }

    // MARK: - Paused quests are exempt from both caps.

    func testPausedMainQuestsDoNotCountAgainstTheMainCap() {
        let userId = UUID()
        var instances: [UserAchievementInstance] = []

        // 3 active Main quests (at the cap).
        for _ in 0..<3 {
            instances.append(
                UserAchievementInstance(
                    id: UUID(),
                    userId: userId,
                    achievementDefinitionId: UUID(),
                    state: .active,
                    questSlotType: .main
                )
            )
        }
        // 2 more Main quests that are paused, not active.
        for _ in 0..<2 {
            instances.append(
                UserAchievementInstance(
                    id: UUID(),
                    userId: userId,
                    achievementDefinitionId: UUID(),
                    state: .paused,
                    questSlotType: .main
                )
            )
        }

        let counts = QuestSlotPolicy.activeSlotCounts(from: instances)
        XCTAssertEqual(counts.main, 3, "Paused Main quests must not count toward the active Main cap.")

        // A user pausing all 3 active Main quests and starting 3 fresh
        // ones must be allowed, per §1.4/§6's "guilt-free take a break."
        let allActiveCounts = QuestSlotPolicy.activeSlotCounts(
            from: instances.map { instance in
                var copy = instance
                if copy.state == .active { copy.state = .paused }
                return copy
            }
        )
        XCTAssertEqual(allActiveCounts.main, 0)
        XCTAssertEqual(
            QuestSlotPolicy.evaluateActivation(
                slotType: .main,
                currentActiveMainCount: allActiveCounts.main,
                currentActiveSideCount: allActiveCounts.side
            ),
            .allowed
        )
    }

    func testPausedSideQuestsDoNotCountAgainstTheSideCap() {
        let userId = UUID()
        let instances: [UserAchievementInstance] = (0..<5).map { _ in
            UserAchievementInstance(
                id: UUID(),
                userId: userId,
                achievementDefinitionId: UUID(),
                state: .paused,
                questSlotType: .side
            )
        }

        let counts = QuestSlotPolicy.activeSlotCounts(from: instances)
        XCTAssertEqual(counts.side, 0)
        XCTAssertEqual(
            QuestSlotPolicy.evaluateActivation(
                slotType: .side,
                currentActiveMainCount: 0,
                currentActiveSideCount: counts.side
            ),
            .allowed
        )
    }
}
