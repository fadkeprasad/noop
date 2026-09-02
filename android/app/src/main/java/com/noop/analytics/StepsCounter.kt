package com.noop.analytics

import com.noop.data.StepSample

/**
 * Wrap-aware step derivation from the strap's cumulative `step_motion_counter@57`, shared by the daily
 * total ([AnalyticsEngine.analyzeDay]) and any windowed total (a manual workout's `[start, end]`, #398).
 *
 * `step_motion_counter@57` is a CUMULATIVE u16 running counter: it can climb with locomotion or other arm
 * motion, and wraps at 65536. The motion-tick total over a set of records is the SUM of WRAP-AWARE
 * increments of that counter — `delta = (cur - prev) and 0xFFFF` — attributed to the later sample's @63
 * activity class. When class data is available, only walk (1) and run (2) deltas count; still (0) and
 * unknown rows are ignored so gym/arm motion does not inflate steps. A window containing only legacy
 * class-less rows keeps the pre-@63 behavior. A per-user `stepTicksPerStep`
 * calibration applied by the caller AFTERWARDS (this returns the raw pre-calibration tick total, so the two
 * callers can never disagree on the counter math). The raw total is an ESTIMATE (@57 counts motion ticks,
 * not validated steps), not cloud/clinical parity.
 *
 * Byte-for-byte twin of the Swift `StepsCounter.stepsInWindow`.
 */
object StepsCounter {
    /**
     * The largest wrap-aware increment treated as real motion between two adjacent 1 Hz records. A delta
     * at/above this is a big time-gap / disconnect boundary between sync sessions (or a firmware reboot,
     * byte-indistinguishable from a u16 wrap), NOT real steps — dropped so gaps don't inflate the total.
     * Real 1 Hz motion never ticks this fast between adjacent records. (#132/#276/#316)
     */
    const val MAX_STEP_DELTA = 512

    /** WHOOP's @63 activity classes that represent actual locomotion (#316): 1=walk, 2=run. */
    internal val LOCOMOTION_ACTIVITY_CLASSES = setOf(1, 2)

    internal fun countsAsStepDelta(activityClass: Int?, classFilterAvailable: Boolean): Boolean =
        !classFilterAvailable || (activityClass != null && activityClass in LOCOMOTION_ACTIVITY_CLASSES)

    /**
     * Raw wrap-aware motion-tick total across [samples] — the sum of positive consecutive
     * `step_motion_counter@57` increments in `[1, MAX_STEP_DELTA)`, filtered to walk/run when @63 activity
     * classes exist in the window. Sorts by `ts` internally, so the caller
     * may pass an unsorted window (already filtered to the range it cares about). Returns `null` when there
     * are fewer than two samples or no forward movement (so "no data" stays distinct from a real zero). The
     * caller applies its `stepTicksPerStep` calibration to the returned ticks.
     */
    fun stepsInWindow(samples: List<StepSample>): Int? {
        val sorted = samples.sortedBy { it.ts }
        if (sorted.size < 2) return null
        // All-null means old data collected before @63 persistence existed. Preserve its historical total;
        // once real class data exists, an isolated null is unknown and must not re-admit arm-motion ticks.
        val classFilterAvailable = sorted.any { it.activityClass != null }
        var total = 0
        for (i in 1 until sorted.size) {
            val delta = (sorted[i].counter - sorted[i - 1].counter) and 0xFFFF // wrap-aware u16 increment
            if (delta in 1 until MAX_STEP_DELTA &&
                countsAsStepDelta(sorted[i].activityClass, classFilterAvailable)
            ) {
                total += delta
            }
        }
        return if (total > 0) total else null
    }
}
