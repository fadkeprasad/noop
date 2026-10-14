import XCTest
@testable import StrandAnalytics

final class SleepStagerOnsetBandTests: XCTestCase {
    private func denseBand(start: Int, epochs: Int, asleepFrom: Int) -> [(ts: Int, state: Int)] {
        (0..<(epochs * 30)).map { offset in
            (ts: start + offset, state: offset / 30 >= asleepFrom ? SleepStager.bandStateAsleep : 1)
        }
    }

    func testConfirmedBandSleepMovesMisclassifiedLeadingSleepToWake() {
        let start = 1_800_000_000
        let stages = [StageSegment(start: start, end: start + 900, stage: "light"),
                      StageSegment(start: start + 900, end: start + 1_800, stage: "deep")]
        let out = SleepStager.applyBandConfirmedOnset(stages, start: start, end: start + 1_800,
            bandSleepState: denseBand(start: start, epochs: 60, asleepFrom: 20), enabled: true)
        XCTAssertEqual(out, [
            StageSegment(start: start, end: start + 600, stage: "wake"),
            StageSegment(start: start + 600, end: start + 900, stage: "light"),
            StageSegment(start: start + 900, end: start + 1_800, stage: "deep"),
        ])
    }

    func testDefaultOffAndAbsentOrSparseBandAreNoOps() {
        let start = 1_800_000_000
        let stages = [StageSegment(start: start, end: start + 1_800, stage: "light")]
        let dense = denseBand(start: start, epochs: 60, asleepFrom: 20)
        XCTAssertEqual(SleepStager.applyBandConfirmedOnset(stages, start: start, end: start + 1_800,
            bandSleepState: dense, enabled: false), stages)
        XCTAssertEqual(SleepStager.applyBandConfirmedOnset(stages, start: start, end: start + 1_800,
            bandSleepState: [], enabled: true), stages)
        let sparse = (0..<60).map { (ts: start + $0 * 30, state: 2) }
        XCTAssertEqual(SleepStager.applyBandConfirmedOnset(stages, start: start, end: start + 1_800,
            bandSleepState: sparse, enabled: true), stages)
    }

    func testGapBreaksConfirmationAndLaterDenseRunCanConfirm() {
        let start = 1_800_000_000
        let stages = [StageSegment(start: start, end: start + 2_700, stage: "light")]
        var samples = denseBand(start: start, epochs: 90, asleepFrom: 20)
        samples.removeAll { (start + 30 * 24 ..< start + 30 * 25).contains($0.ts) }
        let out = SleepStager.applyBandConfirmedOnset(stages, start: start, end: start + 2_700,
            bandSleepState: samples, enabled: true)
        XCTAssertEqual(out.first?.start, start)
        XCTAssertEqual(out.first?.end, start + 30 * 25)
        XCTAssertEqual(out.first?.stage, "wake")
    }

    func testEarlierBandConfirmationNeverMovesOnsetEarlier() {
        let start = 1_800_000_000
        let stages = [StageSegment(start: start, end: start + 900, stage: "wake"),
                      StageSegment(start: start + 900, end: start + 1_800, stage: "light")]
        let out = SleepStager.applyBandConfirmedOnset(stages, start: start, end: start + 1_800,
            bandSleepState: denseBand(start: start, epochs: 60, asleepFrom: 10), enabled: true)
        XCTAssertEqual(out, stages)
    }

    func testBandConfirmationIsBoundedToFirstTwoHours() {
        let start = 1_800_000_000
        let stages = [StageSegment(start: start, end: start + 10_800, stage: "light")]
        let out = SleepStager.applyBandConfirmedOnset(stages, start: start, end: start + 10_800,
            bandSleepState: denseBand(start: start, epochs: 360, asleepFrom: 241), enabled: true)
        XCTAssertEqual(out, stages)
    }
}
