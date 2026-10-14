import XCTest
import StrandDesign
import WhoopStore
@testable import Strand

final class SleepOnsetEstimateTests: XCTestCase {
    func testAsleepClockUsesFirstCoveredFiveMinuteSleepRunButChartKeepsWindowStart() {
        let start = 1_700_000_000
        let session = CachedSleepSession(startTs: start, endTs: start + 3_600,
                                         efficiency: nil, restingHr: nil, avgHrv: nil, stagesJSON: nil)
        let night = Night(session: session, stages: Stages(awake: 10, light: 50, deep: 0, rem: 0),
            realSegments: [
                SleepInterval(stage: .awake, start: 0, end: 600),
                SleepInterval(stage: .light, start: 600, end: 900),
                SleepInterval(stage: .deep, start: 900, end: 1_200),
            ])

        XCTAssertEqual(night.onsetDate.timeIntervalSince1970, TimeInterval(start))
        XCTAssertEqual(night.estimatedSleepOnsetDate?.timeIntervalSince1970, TimeInterval(start + 600))
    }

    func testUncoveredGapCannotCompleteSleepOnsetConfirmation() {
        let start = 1_700_000_000
        let session = CachedSleepSession(startTs: start, endTs: start + 1_000,
                                         efficiency: nil, restingHr: nil, avgHrv: nil, stagesJSON: nil)
        let night = Night(session: session, stages: Stages(awake: 0, light: 20, deep: 0, rem: 0),
            realSegments: [
                SleepInterval(stage: .light, start: 0, end: 150),
                SleepInterval(stage: .light, start: 151, end: 301),
            ])

        XCTAssertNil(night.estimatedSleepOnsetDate, "a one-second hole resets the covered run")
    }
}
