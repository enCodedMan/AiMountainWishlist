import Foundation

/// The three completion-criteria shapes from domain-model.md §1.3. Chosen
/// to cover every achievement type in the constitution's own examples
/// without inventing complexity not yet needed (e.g. no stat-relative
/// thresholds in v0.1 — see the doc's noted deferral).
public enum CompletionCriteria: Equatable, Codable, Sendable {
    /// Did it happen, yes/no. e.g. "Run your first 5K," "Skydive."
    case binary

    /// Reach N occurrences, no deadline. e.g. "Visit 10 countries."
    case cumulativeCount(targetValue: Double, unit: String)

    /// A measured personal-record-style value crosses a bound.
    /// e.g. "Sub-20 5K" (time ≤ 20:00, `.atMost`),
    /// "Bench press 185 lb" (weight ≥ 185, `.atLeast`).
    case thresholdRecord(targetValue: Double, unit: String, comparisonDirection: ComparisonDirection)

    public enum ComparisonDirection: String, Codable, Equatable, Hashable, Sendable {
        case atLeast
        case atMost
    }

    /// Whether a measured value satisfies this criteria. Not used for
    /// `.binary` (binary completion is a direct state transition, not a
    /// measured comparison).
    public func isSatisfied(byMeasuredValue value: Double) -> Bool {
        switch self {
        case .binary:
            return false
        case .cumulativeCount(let targetValue, _):
            return value >= targetValue
        case .thresholdRecord(let targetValue, _, let direction):
            switch direction {
            case .atLeast: return value >= targetValue
            case .atMost: return value <= targetValue
            }
        }
    }
}
