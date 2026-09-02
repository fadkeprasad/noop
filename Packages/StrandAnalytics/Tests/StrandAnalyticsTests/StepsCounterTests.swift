import XCTest
@testable import StrandAnalytics
import WhoopProtocol

/// Unit tests for the shared windowed step kernel `StepsCounter.stepsInWindow` (#398). The same
/// wrap-aware positive-delta math the daily total uses (see StepsDailyTests), but exercised directly and
/// order-independently so a manual-workout window can reuse it. Returns the RAW motion-tick total (before
/// the caller's `stepTicksPerStep` calibration). Mirrors the Android StepsCounterTest vectors value-for-value.
final class StepsCounterTests: XCTestCase {

    private func step(_ ts: Int, _ counter: Int, _ activityClass: Int? = nil) -> StepSample {
        StepSample(ts: ts, counter: counter, activityClass: activityClass)
    }

    func testSumsPositiveConsecutiveDeltas() {
        // counters 100 -> 150 -> 220 => deltas 50 + 70 = 120
        XCTAssertEqual(StepsCounter.stepsInWindow([step(0, 100), step(60, 150), step(120, 220)]), 120)
    }

    func testSortsUnorderedInput() {
        // Same three samples shuffled — the kernel sorts by ts, so the result is identical (120).
        XCTAssertEqual(StepsCounter.stepsInWindow([step(120, 220), step(0, 100), step(60, 150)]), 120)
    }

    func testHandlesU16Wraparound() {
        // 65500 -> 20 wraps: (20 - 65500) & 0xFFFF = 56, a small real increment; then 20 -> 80 => 60.
        XCTAssertEqual(StepsCounter.stepsInWindow([step(0, 65_500), step(60, 20), step(120, 80)]), 116)
    }

    func testFewerThanTwoSamplesIsNil() {
        XCTAssertNil(StepsCounter.stepsInWindow([]))
        XCTAssertNil(StepsCounter.stepsInWindow([step(0, 100)]))
    }

    func testNoForwardMovementIsNil() {
        // Flat counter across the window => no positive delta => nil (not 0).
        XCTAssertNil(StepsCounter.stepsInWindow([step(0, 500), step(60, 500), step(120, 500)]))
    }

    func testDropsBigGapDeltaAsBoundary() {
        // A jump >= 512 (sync-gap / reboot boundary) is dropped; the real 40 + 30 survive.
        // 100 -> 140 (=40) -> 5000 (=4860, dropped) -> 5030 (=30) => 70.
        XCTAssertEqual(StepsCounter.stepsInWindow(
            [step(0, 100), step(60, 140), step(120, 5_000), step(180, 5_030)]), 70)
    }

    func testMaxStepDeltaBoundaryIsExclusive() {
        // Exactly maxStepDelta (512) is dropped; 511 counts.
        XCTAssertEqual(StepsCounter.stepsInWindow([step(0, 0), step(60, 512)]), nil)   // 512 dropped => no movement
        XCTAssertEqual(StepsCounter.stepsInWindow([step(0, 0), step(60, 511)]), 511)   // 511 kept
    }

    func testCountsOnlyWalkAndRunWhenActivityClassesAreAvailable() {
        // Deltas are attributed to the later sample: still 50 and unknown 30 are ignored; walk 70 and run
        // 40 count. This rejects gym/arm motion while retaining actual locomotion on WHOOP 5/MG (#1780).
        let samples = [
            step(0, 100, 0), step(60, 150, 0), step(120, 220, 1),
            step(180, 250, nil), step(240, 290, 2),
        ]
        XCTAssertEqual(StepsCounter.stepsInWindow(samples), 110)
    }

    func testAllUnknownActivityClassesPreserveLegacyCounterBehavior() {
        // Pre-@63 rows have no activity class at all, so their historical 50 + 70 total remains readable.
        XCTAssertEqual(StepsCounter.stepsInWindow(
            [step(0, 100, nil), step(60, 150, nil), step(120, 220, nil)]), 120)
    }
}
