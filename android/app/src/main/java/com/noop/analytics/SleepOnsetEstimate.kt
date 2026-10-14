package com.noop.analytics

/** Mirrors Swift SleepOnsetEstimate: first continuously covered five-minute sleep run. */
object SleepOnsetEstimate {
    fun timestamp(stages: List<StageSegment>): Long? {
        var runStart: Long? = null
        var runEnd: Long? = null
        for (segment in stages.sortedBy { it.start }) {
            if (segment.end <= segment.start) continue
            if (segment.stage !in listOf("light", "deep", "rem")) {
                runStart = null
                runEnd = null
                continue
            }
            if (runEnd != null && segment.start != runEnd) runStart = null
            if (runStart == null) runStart = segment.start
            runEnd = segment.end
            val start = runStart
            if (segment.end - start >= 300L) return start
        }
        return null
    }
}
