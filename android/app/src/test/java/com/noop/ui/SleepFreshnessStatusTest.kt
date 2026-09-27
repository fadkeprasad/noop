package com.noop.ui

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class SleepFreshnessStatusTest {
    @Test fun currentNightNeedsNoBanner() {
        assertNull(resolveSleepFreshness(true, true, false, false, true, false))
    }

    @Test fun doesNotDeclareMissingBeforeMorning() {
        assertNull(resolveSleepFreshness(false, false, false, false, true, false))
    }

    @Test fun progressStatesWinOverStaleHistory() {
        assertEquals(
            SleepFreshnessStatus.SYNCING,
            resolveSleepFreshness(false, true, true, true, false, true),
        )
        assertEquals(
            SleepFreshnessStatus.CALCULATING,
            resolveSleepFreshness(false, true, false, true, true, true),
        )
    }

    @Test fun completedSyncWithoutNightIsExplicitlyNotDetected() {
        assertEquals(
            SleepFreshnessStatus.NOT_DETECTED,
            resolveSleepFreshness(false, true, false, false, true, false),
        )
    }

    @Test fun distinguishesFailedAndNotYetRunSyncs() {
        assertEquals(
            SleepFreshnessStatus.SYNC_FAILED,
            resolveSleepFreshness(false, true, false, false, false, true),
        )
        assertEquals(
            SleepFreshnessStatus.AWAITING_SYNC,
            resolveSleepFreshness(false, true, false, false, false, false),
        )
    }

    /** A visible night can still change during a sync-triggered rescore; use distinct copy. */
    @Test
    fun `a night already in hand reports updating during calculating`() {
        assertEquals(
            SleepFreshnessStatus.UPDATING,
            resolveSleepFreshness(true, true, false, true, true, false),
        )
    }

    /**
     * SYNCING deliberately still outranks a present night: data landing now can change what is shown,
     * so that one is informative where CALCULATING is merely noisy. Pinned so the fix above is not
     * later "tidied" into suppressing both.
     */
    @Test
    fun `syncing still shows even with a night in hand`() {
        assertEquals(
            SleepFreshnessStatus.SYNCING,
            resolveSleepFreshness(true, true, true, true, true, false),
        )
    }

    /**
     * Before morning with nothing detected yet, CALCULATING still wins over the quiet return, so the
     * reorder did not silence the one case that genuinely reports work in progress.
     */
    @Test
    fun `calculating still shows before morning when no night exists`() {
        assertEquals(
            SleepFreshnessStatus.CALCULATING,
            resolveSleepFreshness(false, false, false, true, false, false),
        )
    }
}
