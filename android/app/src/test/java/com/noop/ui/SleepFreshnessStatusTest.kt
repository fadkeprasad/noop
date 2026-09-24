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

    /**
     * A score already on screen stays visible during a post-sync calculation, but the status must say it
     * can still change. A silent return made a provisional wake boundary look final.
     */
    @Test
    fun `a night already in hand shows calculating while it updates`() {
        assertEquals(
            SleepFreshnessStatus.CALCULATING,
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
