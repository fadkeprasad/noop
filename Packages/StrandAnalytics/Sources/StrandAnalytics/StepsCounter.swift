import Foundation
import WhoopProtocol

/// Wrap-aware step derivation from the strap's cumulative `step_motion_counter@57`, shared by the daily
/// total (`AnalyticsEngine.analyzeDay`) and any windowed total (a manual workout's `[start, end]`, #398).
///
/// `step_motion_counter@57` is a CUMULATIVE u16 running counter: it can climb with locomotion or other arm
/// motion, and wraps at 65536. The number of motion ticks over a set of time-ordered records is the SUM of
/// WRAP-AWARE increments of that counter — `delta = (cur - prev) & 0xFFFF` — attributed to the later
/// sample's @63 activity class. When class data is available, only walk (1) and run (2) deltas count;
/// still (0) and unknown rows are ignored so gym/arm motion does not inflate steps. A window containing
/// only legacy class-less rows keeps the pre-@63 behavior. A per-user
/// `stepTicksPerStep` calibration applied by the caller AFTERWARDS (this returns the raw pre-calibration
/// tick total, so the two callers can never disagree on the counter math). The raw total is an ESTIMATE
/// (@57 counts motion ticks, not validated steps), not cloud/clinical parity.
///
/// Kept byte-for-byte in lockstep with the Kotlin twin `StepsCounter.stepsInWindow`.
public enum StepsCounter {
    /// The largest wrap-aware increment treated as real motion between two adjacent 1 Hz records. A delta
    /// at/above this is a big time-gap / disconnect boundary between sync sessions (or a firmware reboot,
    /// byte-indistinguishable from a u16 wrap), NOT real steps — dropped so gaps don't inflate the total.
    /// Real 1 Hz motion never ticks this fast between adjacent records. (#132/#276/#316)
    public static let maxStepDelta = 512

    /// WHOOP's @63 activity classes that represent actual locomotion (#316): 1=walk, 2=run.
    /// Kept internal so the production counter and diagnostic trace share the exact same decision.
    static let locomotionActivityClasses: Set<Int> = [1, 2]

    static func countsAsStepDelta(activityClass: Int?, classFilterAvailable: Bool) -> Bool {
        guard classFilterAvailable else { return true }  // legacy/pre-migration rows
        guard let activityClass else { return false }
        return locomotionActivityClasses.contains(activityClass)
    }

    /// Raw wrap-aware motion-tick total across `samples` — the sum of positive consecutive
    /// `step_motion_counter@57` increments in `[1, maxStepDelta)`, filtered to walk/run when @63 activity
    /// classes exist in the window. Sorts by `ts` internally, so the caller
    /// may pass an unsorted window (already filtered to the range it cares about). Returns `nil` when there
    /// are fewer than two samples or no forward movement (so "no data" stays distinct from a real zero).
    /// The caller applies its `stepTicksPerStep` calibration to the returned ticks.
    public static func stepsInWindow(_ samples: [StepSample]) -> Int? {
        let sorted = samples.sorted { $0.ts < $1.ts }
        if sorted.count < 2 { return nil }
        // All-nil means old data collected before @63 persistence existed. Preserve its historical total;
        // once real class data exists, an isolated nil is unknown and must not re-admit arm-motion ticks.
        let classFilterAvailable = sorted.contains { $0.activityClass != nil }
        var total = 0
        for i in 1..<sorted.count {
            let delta = (sorted[i].counter - sorted[i - 1].counter) & 0xFFFF  // wrap-aware u16 increment
            if delta >= 1 && delta < maxStepDelta
                && countsAsStepDelta(activityClass: sorted[i].activityClass,
                                     classFilterAvailable: classFilterAvailable) {
                total += delta
            }
        }
        return total > 0 ? total : nil
    }
}
