import XCTest
@testable import LifeAchievementCore

final class AchievementStateMachineTests: XCTestCase {

    // Every legal (from, trigger) -> to row from domain-model.md §1.4's
    // transition table, verified exactly once each (18 rows).
    func testEveryLegalTransitionInTheSpecTableSucceeds() throws {
        let legalTransitions: [(AchievementState, AchievementTransitionTrigger, AchievementState)] = [
            (.notDiscovered, .discover, .discovered),
            (.discovered, .saveToBacklog, .interested),
            (.discovered, .activate, .active),
            (.discovered, .markCompleted, .completed),
            (.discovered, .abandon, .abandoned),
            (.interested, .activate, .active),
            (.interested, .abandon, .abandoned),
            (.interested, .markCompleted, .completed),
            (.active, .markCompleted, .completed),
            (.active, .pause, .paused),
            (.active, .abandon, .abandoned),
            (.active, .demoteToBacklog, .interested),
            (.paused, .resume, .active),
            (.paused, .abandon, .abandoned),
            (.paused, .markCompleted, .completed),
            (.abandoned, .reconsider, .interested),
            (.abandoned, .activate, .active),
            (.completed, .undoCompletion, .discovered)
        ]

        XCTAssertEqual(legalTransitions.count, 18, "Sanity check: the spec table has exactly 18 rows.")

        for (from, trigger, expectedTo) in legalTransitions {
            XCTAssertTrue(AchievementStateMachine.canTransition(from: from, trigger: trigger))
            let to = try AchievementStateMachine.transition(from: from, trigger: trigger)
            XCTAssertEqual(to, expectedTo, "\(from) + \(trigger) should reach \(expectedTo)")
        }
    }

    // Every (from, trigger) pair NOT in the table above must be rejected.
    // Exhaustively checked, plus a few of the most easily-miscoded illegal
    // paths called out explicitly for readability.
    func testEveryOtherPairIsRejected() {
        let legalPairs: Set<PairKey> = [
            PairKey(.notDiscovered, .discover),
            PairKey(.discovered, .saveToBacklog),
            PairKey(.discovered, .activate),
            PairKey(.discovered, .markCompleted),
            PairKey(.discovered, .abandon),
            PairKey(.interested, .activate),
            PairKey(.interested, .abandon),
            PairKey(.interested, .markCompleted),
            PairKey(.active, .markCompleted),
            PairKey(.active, .pause),
            PairKey(.active, .abandon),
            PairKey(.active, .demoteToBacklog),
            PairKey(.paused, .resume),
            PairKey(.paused, .abandon),
            PairKey(.paused, .markCompleted),
            PairKey(.abandoned, .reconsider),
            PairKey(.abandoned, .activate),
            PairKey(.completed, .undoCompletion)
        ]

        for from in AchievementState.allCases {
            for trigger in AchievementTransitionTrigger.allCases {
                let pair = PairKey(from, trigger)
                if legalPairs.contains(pair) { continue }
                XCTAssertFalse(
                    AchievementStateMachine.canTransition(from: from, trigger: trigger),
                    "\(from) + \(trigger) should be illegal"
                )
                XCTAssertThrowsError(try AchievementStateMachine.transition(from: from, trigger: trigger))
            }
        }
    }

    // Named illegal transitions called out explicitly in the task/spec,
    // e.g. completed -> active directly (must go through undoCompletion
    // back to discovered, then be re-activated as a separate step).
    func testCompletedCannotTransitionDirectlyToActive() {
        XCTAssertFalse(AchievementStateMachine.canTransition(from: .completed, trigger: .activate))
        XCTAssertThrowsError(try AchievementStateMachine.transition(from: .completed, trigger: .activate)) { error in
            guard let illegal = error as? IllegalAchievementTransition else {
                return XCTFail("Expected IllegalAchievementTransition, got \(error)")
            }
            XCTAssertEqual(illegal.from, .completed)
            XCTAssertEqual(illegal.trigger, .activate)
        }
    }

    func testNotDiscoveredCannotSkipStraightToActive() {
        XCTAssertFalse(AchievementStateMachine.canTransition(from: .notDiscovered, trigger: .activate))
    }

    func testPausedCannotDemoteDirectlyToInterested() {
        // Only `.active` has a demoteToBacklog path in the table; paused
        // must resume first.
        XCTAssertFalse(AchievementStateMachine.canTransition(from: .paused, trigger: .demoteToBacklog))
    }

    func testAbandonedCannotMarkCompletedDirectly() {
        XCTAssertFalse(AchievementStateMachine.canTransition(from: .abandoned, trigger: .markCompleted))
    }

    // MARK: - Test support

    private struct PairKey: Hashable {
        let from: AchievementState
        let trigger: AchievementTransitionTrigger
        init(_ from: AchievementState, _ trigger: AchievementTransitionTrigger) {
            self.from = from
            self.trigger = trigger
        }
    }
}
