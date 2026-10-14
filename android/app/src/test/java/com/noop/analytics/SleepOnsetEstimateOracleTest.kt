package com.noop.analytics

import org.junit.Assert.assertEquals
import org.junit.Test

class SleepOnsetEstimateOracleTest {
    @Test
    fun matchesStandaloneSwiftOracle() {
        val cases = listOf(
            listOf(StageSegment(0, 150, "wake"), StageSegment(150, 300, "light"), StageSegment(300, 450, "deep")),
            listOf(StageSegment(100, 250, "light"), StageSegment(251, 401, "light")),
            listOf(StageSegment(100, 250, "light"), StageSegment(250, 280, "wake"), StageSegment(280, 580, "rem")),
            listOf(StageSegment(20, 320, "light")),
            listOf(StageSegment(20, 319, "light")),
        )

        // Literal output from compiling SleepOnsetEstimate.swift with `swiftc`.
        assertEquals(listOf(150L, null, 280L, 20L, null), cases.map(SleepOnsetEstimate::timestamp))
    }
}
