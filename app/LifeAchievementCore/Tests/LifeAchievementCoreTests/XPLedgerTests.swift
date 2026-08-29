import XCTest
@testable import LifeAchievementCore

final class XPLedgerTests: XCTestCase {
    let userId = UUID()

    func testGrantThenReverseNetsToZero() throws {
        var ledger = XPLedger()
        let entry = ledger.grant(userId: userId, category: .fitness, amount: 250)
        XCTAssertEqual(ledger.totalXP(userId: userId), 250)

        _ = try ledger.reverse(entryId: entry.id)
        XCTAssertEqual(ledger.totalXP(userId: userId), 0)
        XCTAssertEqual(ledger.totalXP(userId: userId, category: .fitness), 0)
    }

    func testReversingOneEntryDoesNotTouchOthers() throws {
        var ledger = XPLedger()
        let a = ledger.grant(userId: userId, category: .fitness, amount: 100)
        let b = ledger.grant(userId: userId, category: .travel, amount: 500)
        let c = ledger.grant(userId: userId, category: .fitness, amount: 25)

        XCTAssertEqual(ledger.totalXP(userId: userId), 625)

        _ = try ledger.reverse(entryId: b.id)

        // b is reversed; a and c stand untouched.
        XCTAssertEqual(ledger.totalXP(userId: userId), 125)
        XCTAssertEqual(ledger.totalXP(userId: userId, category: .fitness), 125)
        XCTAssertEqual(ledger.totalXP(userId: userId, category: .travel), 0)

        // The original entries themselves are unmodified (append-only).
        XCTAssertTrue(ledger.entries.contains(a))
        XCTAssertTrue(ledger.entries.contains(c))
        XCTAssertEqual(ledger.entries.count, 4) // 3 grants + 1 reversal
    }

    func testReversingUnknownEntryThrows() {
        var ledger = XPLedger()
        XCTAssertThrowsError(try ledger.reverse(entryId: UUID())) { error in
            guard case XPLedgerError.entryNotFound = error else {
                return XCTFail("Expected .entryNotFound, got \(error)")
            }
        }
    }

    func testReversingTheSameEntryTwiceThrows() throws {
        var ledger = XPLedger()
        let entry = ledger.grant(userId: userId, category: .skills, amount: 50)
        _ = try ledger.reverse(entryId: entry.id)

        XCTAssertThrowsError(try ledger.reverse(entryId: entry.id)) { error in
            guard case XPLedgerError.entryAlreadyReversed = error else {
                return XCTFail("Expected .entryAlreadyReversed, got \(error)")
            }
        }
    }

    func testReversingAReversalThrows() throws {
        var ledger = XPLedger()
        let entry = ledger.grant(userId: userId, category: .skills, amount: 50)
        let reversal = try ledger.reverse(entryId: entry.id)

        XCTAssertThrowsError(try ledger.reverse(entryId: reversal.id)) { error in
            guard case XPLedgerError.cannotReverseAReversalEntry = error else {
                return XCTFail("Expected .cannotReverseAReversalEntry, got \(error)")
            }
        }
    }

    func testUndoRedoDoesNotDoubleGrant() throws {
        // Regression guard for the exact failure mode domain-model.md
        // §3.4 calls out: complete -> undo -> redo must not net more than
        // one grant's worth of XP.
        var ledger = XPLedger()
        let first = ledger.grant(userId: userId, category: .adventure, amount: 500)
        _ = try ledger.reverse(entryId: first.id)
        let redo = ledger.grant(userId: userId, category: .adventure, amount: 500)

        XCTAssertEqual(ledger.totalXP(userId: userId), 500)
        XCTAssertNotEqual(first.id, redo.id)
    }

    func testTotalXPIsScopedPerUser() {
        var ledger = XPLedger()
        let otherUser = UUID()
        ledger.grant(userId: userId, category: .fitness, amount: 100)
        ledger.grant(userId: otherUser, category: .fitness, amount: 9_999)

        XCTAssertEqual(ledger.totalXP(userId: userId), 100)
        XCTAssertEqual(ledger.totalXP(userId: otherUser), 9_999)
    }
}
