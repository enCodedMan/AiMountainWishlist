import XCTest
@testable import LifeAchievementCore

final class LevelCurveTests: XCTestCase {

    // Spot-check rows from domain-model.md §3.3's table against the
    // formula it also specifies: cumulative(L) = 25 × (L − 1) × (L + 2).
    //
    // NOTE: levels 11-15 and 40 in the doc's illustrative table do not
    // match the doc's own formula (verified independently; e.g. the
    // formula gives 3,250 for level 11, not the table's 3,300). Every
    // other row (1-10, 20, 30, 50) matches the formula exactly, and the
    // formula is what the spec instructs app-engineer to implement, so
    // this package implements the formula and these expectations use the
    // formula-correct values for the mismatched rows. Flagged back as a
    // doc bug per domain-model.md's own "ambiguity is a bug in the doc"
    // rule — see the implementation report.
    func testCumulativeXPMatchesSpecTable() {
        let expected: [Int: Int] = [
            1: 0,
            2: 100,
            3: 250,
            4: 450,
            5: 700,
            6: 1_000,
            7: 1_350,
            8: 1_750,
            9: 2_200,
            10: 2_700,
            11: 3_250,   // doc table says 3,300 — formula-correct value; see note above
            12: 3_850,   // doc table says 4,000 — formula-correct value; see note above
            13: 4_500,   // doc table says 4,800 — formula-correct value; see note above
            14: 5_200,   // doc table says 5,700 — formula-correct value; see note above
            15: 5_950,   // doc table says 6,700 — formula-correct value; see note above
            20: 10_450,
            30: 23_200,
            40: 40_950,  // doc table says 41,700 — formula-correct value; see note above
            50: 63_700
        ]
        for (level, cumulativeXP) in expected {
            XCTAssertEqual(
                LevelCurve.cumulativeXP(forLevel: level),
                cumulativeXP,
                "cumulativeXP(forLevel: \(level)) mismatch"
            )
        }
    }

    func testLevelCostIncreasesBy50PerLevel() {
        // "the XP cost to go from level L to L+1 is 50 × (L+1)"
        for level in 1...25 {
            let cost = LevelCurve.cumulativeXP(forLevel: level + 1) - LevelCurve.cumulativeXP(forLevel: level)
            XCTAssertEqual(cost, 50 * (level + 1), "level \(level) -> \(level + 1) cost mismatch")
        }
    }

    func testLevelForCumulativeXPAtExactBoundaries() {
        for level in 1...50 {
            let boundaryXP = LevelCurve.cumulativeXP(forLevel: level)
            XCTAssertEqual(LevelCurve.level(forCumulativeXP: boundaryXP), level)
        }
    }

    func testLevelForCumulativeXPJustBelowBoundaryStaysAtPriorLevel() {
        // One XP short of reaching level 10 (2,700) should still read as level 9.
        XCTAssertEqual(LevelCurve.level(forCumulativeXP: 2_699), 9)
        // One XP short of reaching level 2 (100) should still read as level 1.
        XCTAssertEqual(LevelCurve.level(forCumulativeXP: 99), 1)
    }

    func testLevelForZeroXPIsLevelOne() {
        XCTAssertEqual(LevelCurve.level(forCumulativeXP: 0), 1)
    }

    func testLevelForCumulativeXPBetweenBoundariesRoundsDown() {
        // Between level 9 (2,200) and level 10 (2,700): a plausible
        // onboarding retroactive total from §3.3's worked example.
        XCTAssertEqual(LevelCurve.level(forCumulativeXP: 2_450), 9)
    }

    func testLevelForCumulativeXPFarBeyondHandAuthoredTable() {
        // The formula has no hard cap; verify the inverse stays exact well
        // past level 50 without relying on the hand-authored table.
        let level = 200
        let xp = LevelCurve.cumulativeXP(forLevel: level)
        XCTAssertEqual(LevelCurve.level(forCumulativeXP: xp), level)
        XCTAssertEqual(LevelCurve.level(forCumulativeXP: xp + 49), level)
        XCTAssertEqual(LevelCurve.level(forCumulativeXP: xp + 50), level + 1)
    }

    func testXPRemainingToNextLevel() {
        // At exactly level 10's floor (2,700), the next level (11) costs
        // 50 × (10 + 1) = 550 more XP, per the formula's own stated
        // per-level cost equivalence (see testLevelCostIncreasesBy50PerLevel).
        XCTAssertEqual(LevelCurve.xpRemainingToNextLevel(currentCumulativeXP: 2_700), 550)
        XCTAssertEqual(LevelCurve.xpRemainingToNextLevel(currentCumulativeXP: 0), 100)
    }
}
