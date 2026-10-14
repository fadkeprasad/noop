import XCTest
@testable import StrandAnalytics

final class SleepOnsetEstimateTests: XCTestCase {
    func testContinuousFiveMinuteRunsMatchCrossPlatformOracle() {
        let cases: [[StageSegment]] = [
            [StageSegment(start: 0, end: 150, stage: "wake"),
             StageSegment(start: 150, end: 300, stage: "light"),
             StageSegment(start: 300, end: 450, stage: "deep")],
            [StageSegment(start: 100, end: 250, stage: "light"),
             StageSegment(start: 251, end: 401, stage: "light")],
            [StageSegment(start: 100, end: 250, stage: "light"),
             StageSegment(start: 250, end: 280, stage: "wake"),
             StageSegment(start: 280, end: 580, stage: "rem")],
            [StageSegment(start: 20, end: 320, stage: "light")],
            [StageSegment(start: 20, end: 319, stage: "light")],
        ]

        // `swiftc` oracle stdout: 150, null, 280, 20, null.
        XCTAssertEqual(cases.map { SleepOnsetEstimate.timestamp(stages: $0) },
                       [150, nil, 280, 20, nil])
    }
}
