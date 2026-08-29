import XCTest
@testable import LifeAchievementCore

final class SupportingTypesTests: XCTestCase {

    // MARK: - CompletionCriteria

    func testThresholdRecordAtLeastDirection() {
        let criteria = CompletionCriteria.thresholdRecord(targetValue: 135, unit: "lb", comparisonDirection: .atLeast)
        XCTAssertTrue(criteria.isSatisfied(byMeasuredValue: 135))
        XCTAssertTrue(criteria.isSatisfied(byMeasuredValue: 200))
        XCTAssertFalse(criteria.isSatisfied(byMeasuredValue: 134.9))
    }

    func testThresholdRecordAtMostDirection() {
        // "Sub-20 5K": time in minutes must be <= 20.
        let criteria = CompletionCriteria.thresholdRecord(targetValue: 20, unit: "min", comparisonDirection: .atMost)
        XCTAssertTrue(criteria.isSatisfied(byMeasuredValue: 19.5))
        XCTAssertTrue(criteria.isSatisfied(byMeasuredValue: 20))
        XCTAssertFalse(criteria.isSatisfied(byMeasuredValue: 20.1))
    }

    func testCumulativeCountSatisfaction() {
        let criteria = CompletionCriteria.cumulativeCount(targetValue: 10, unit: "countries")
        XCTAssertFalse(criteria.isSatisfied(byMeasuredValue: 9))
        XCTAssertTrue(criteria.isSatisfied(byMeasuredValue: 10))
        XCTAssertTrue(criteria.isSatisfied(byMeasuredValue: 11))
    }

    // MARK: - XPBand (§3.1 discrete value rule)

    func testValidBuiltInXPValues() {
        for value in [10, 50, 100, 500, 1000, 2500, 5000, 10000] {
            XCTAssertTrue(XPBand.isValidBuiltInXPValue(value), "\(value) should be a valid band value")
        }
    }

    func testInvalidBuiltInXPValueIsRejected() {
        XCTAssertFalse(XPBand.isValidBuiltInXPValue(333))
        XCTAssertFalse(XPBand.isValidBuiltInXPValue(0))
    }

    func testExceptionalBandIsNotValidForUserCreatedContent() {
        // §3.4: Exceptional band (2,500-10,000+) is reserved for
        // built-in/AI-vetted content only in v0.1.
        XCTAssertTrue(XPBand.isValidBuiltInXPValue(5000))
        XCTAssertFalse(XPBand.isValidUserCreatedXPValue(5000))
        XCTAssertTrue(XPBand.isValidUserCreatedXPValue(2500)) // Major band ceiling is still allowed
    }

    // MARK: - UserAchievementInstance entry-point factories (§1.4 special cases)

    func testDiscoveredFactoryCreatesDiscoveredState() {
        let instance = UserAchievementInstance.discovered(userId: UUID(), achievementDefinitionId: UUID())
        XCTAssertEqual(instance.state, .discovered)
        XCTAssertNotNil(instance.discoveredAt)
        XCTAssertNil(instance.activatedAt)
    }

    func testUserCreatedFactorySkipsDiscoveredAndInterestedWaypoints() {
        let asActive = UserAchievementInstance.userCreated(
            userId: UUID(),
            achievementDefinitionId: UUID(),
            startingAs: .active,
            questSlotType: .side
        )
        XCTAssertEqual(asActive.state, .active)
        XCTAssertEqual(asActive.questSlotType, .side)
        XCTAssertNotNil(asActive.activatedAt)

        let asInterested = UserAchievementInstance.userCreated(
            userId: UUID(),
            achievementDefinitionId: UUID(),
            startingAs: .interested
        )
        XCTAssertEqual(asInterested.state, .interested)
        XCTAssertEqual(asInterested.questSlotType, .none)
        XCTAssertNil(asInterested.activatedAt)
    }

    func testIntegrationVerifiedCompletionSkipsAllIntermediateStates() {
        let instance = UserAchievementInstance.integrationVerifiedCompletion(
            userId: UUID(),
            achievementDefinitionId: UUID(),
            xpLedgerEntryId: UUID()
        )
        XCTAssertEqual(instance.state, .completed)
        XCTAssertEqual(instance.verificationLevel, .verified)
        XCTAssertNotNil(instance.completedAt)
        XCTAssertNotNil(instance.xpLedgerEntryId)
    }

    // MARK: - Category

    func testGeneralCategoryIsNotBrowsable() {
        XCTAssertFalse(Category.general.isBrowsable)
        for category in Category.allCases where category != .general {
            XCTAssertTrue(category.isBrowsable)
        }
    }

    func testAllTenCategoriesPlusGeneralExist() {
        XCTAssertEqual(Category.allCases.count, 11)
    }
}
