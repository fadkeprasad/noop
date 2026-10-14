package com.noop.analytics

import org.junit.Assert.assertEquals
import org.junit.Test

/** Android twin of `SleepStagerOnsetBandTests.swift`. */
class SleepStagerOnsetBandTest {
    private fun denseBand(start: Long, epochs: Int, asleepFrom: Int): List<Pair<Long, Int>> =
        (0 until epochs * 30).map { offset ->
            (start + offset) to if (offset / 30 >= asleepFrom) SleepStager.bandStateAsleep else 1
        }

    @Test
    fun confirmedBandSleepMovesMisclassifiedLeadingSleepToWake() {
        val start = 1_800_000_000L
        val stages = listOf(
            StageSegment(start, start + 900, "light"),
            StageSegment(start + 900, start + 1_800, "deep"),
        )
        val out = SleepStager.applyBandConfirmedOnset(
            stages, start, start + 1_800, denseBand(start, 60, 20), enabled = true,
        )
        assertEquals(
            listOf(
                StageSegment(start, start + 600, "wake"),
                StageSegment(start + 600, start + 900, "light"),
                StageSegment(start + 900, start + 1_800, "deep"),
            ),
            out,
        )
    }

    @Test
    fun disabledAbsentAndSparseBandAreNoOps() {
        val start = 1_800_000_000L
        val stages = listOf(StageSegment(start, start + 1_800, "light"))
        val dense = denseBand(start, 60, 20)
        assertEquals(stages, SleepStager.applyBandConfirmedOnset(stages, start, start + 1_800, dense))
        assertEquals(stages, SleepStager.applyBandConfirmedOnset(stages, start, start + 1_800, emptyList(), true))
        val sparse = (0 until 60).map { (start + it * 30L) to 2 }
        assertEquals(stages, SleepStager.applyBandConfirmedOnset(stages, start, start + 1_800, sparse, true))
    }

    @Test
    fun gapBreaksConfirmationAndLaterDenseRunCanConfirm() {
        val start = 1_800_000_000L
        val stages = listOf(StageSegment(start, start + 2_700, "light"))
        val samples = denseBand(start, 90, 20).filterNot {
            it.first >= start + 30 * 24 && it.first < start + 30 * 25
        }
        val out = SleepStager.applyBandConfirmedOnset(stages, start, start + 2_700, samples, true)
        assertEquals(StageSegment(start, start + 30 * 25, "wake"), out.first())
    }

    @Test
    fun earlierBandConfirmationNeverMovesOnsetEarlier() {
        val start = 1_800_000_000L
        val stages = listOf(
            StageSegment(start, start + 900, "wake"),
            StageSegment(start + 900, start + 1_800, "light"),
        )
        val out = SleepStager.applyBandConfirmedOnset(
            stages, start, start + 1_800, denseBand(start, 60, 10), true,
        )
        assertEquals(stages, out)
    }

    @Test
    fun bandConfirmationIsBoundedToFirstTwoHours() {
        val start = 1_800_000_000L
        val stages = listOf(StageSegment(start, start + 10_800, "light"))
        val out = SleepStager.applyBandConfirmedOnset(
            stages, start, start + 10_800, denseBand(start, 360, 241), true,
        )
        assertEquals(stages, out)
    }
}
