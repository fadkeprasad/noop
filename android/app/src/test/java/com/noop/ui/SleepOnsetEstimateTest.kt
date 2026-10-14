package com.noop.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SleepOnsetEstimateTest {
    @Test
    fun firstCoveredFiveMinuteSleepRunIsRetrospectiveOnset() {
        val segments = listOf(
            PersistedSegment(1_700_000_000L, 1_700_000_600L, "wake"),
            PersistedSegment(1_700_000_600L, 1_700_000_900L, "light"),
            PersistedSegment(1_700_000_900L, 1_700_001_200L, "deep"),
        )
        assertEquals(1_700_000_600L, estimateSleepOnsetTs(segments) ?: -1L)
    }

    @Test
    fun aGapOrAwakeSegmentResetsOnsetConfirmation() {
        val gap = listOf(
            PersistedSegment(100L, 250L, "light"),
            PersistedSegment(251L, 401L, "light"),
        )
        assertNull(estimateSleepOnsetTs(gap))
        val interrupted = listOf(
            PersistedSegment(100L, 250L, "light"),
            PersistedSegment(250L, 280L, "awake"),
            PersistedSegment(280L, 430L, "light"),
        )
        assertNull(estimateSleepOnsetTs(interrupted))
    }
}
