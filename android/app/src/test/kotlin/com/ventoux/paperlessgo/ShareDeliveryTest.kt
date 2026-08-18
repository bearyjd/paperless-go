package com.ventoux.paperlessgo

import android.content.Intent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Regression coverage for the two ways a *successfully resolved* share still
 * reached the user as nothing at all — both observed in logcat on a real
 * device share, after the URI selection covered by [SharePluginUriSelectionTest]
 * had already been fixed:
 *
 *  - "resolved 1 file(s), eventSink=false" — the intent beat Dart's
 *    EventChannel listener and the payload was dropped on a null sink.
 *  - "getInitialShare returned: []" — activity.intent was stale, so the
 *    follow-up query resolved the wrong intent.
 *
 * Fixing the second (calling setIntent) is what makes the third case below
 * possible, so the delivery mark is tested alongside it.
 */
class ShareDeliveryBufferTest {
    @Test
    fun `payload delivered while a listener is attached goes straight through`() {
        val buffer = ShareDeliveryBuffer()
        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        buffer.deliver("[{\"path\":\"/a.pdf\"}]")

        assertEquals(listOf("[{\"path\":\"/a.pdf\"}]"), received)
    }

    @Test
    fun `payload delivered before any listener is replayed on attach`() {
        val buffer = ShareDeliveryBuffer()
        buffer.deliver("[{\"path\":\"/a.pdf\"}]")
        assertEquals(1, buffer.bufferedCount)

        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        assertEquals(listOf("[{\"path\":\"/a.pdf\"}]"), received)
        assertEquals(0, buffer.bufferedCount)
    }

    @Test
    fun `two shares arriving before a listener are both replayed, in order`() {
        val buffer = ShareDeliveryBuffer()
        buffer.deliver("first")
        buffer.deliver("second")

        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        assertEquals(listOf("first", "second"), received)
    }

    @Test
    fun `a replayed payload is not delivered again on a later attach`() {
        val buffer = ShareDeliveryBuffer()
        buffer.deliver("only once")
        buffer.attach { }
        buffer.detach()

        val received = mutableListOf<String>()
        buffer.attach { received.add(it) }

        assertEquals(emptyList<String>(), received)
    }

    @Test
    fun `payloads buffer again after the listener detaches`() {
        val buffer = ShareDeliveryBuffer()
        buffer.attach { }
        buffer.detach()

        buffer.deliver("while detached")

        assertEquals(1, buffer.bufferedCount)
    }
}

class ShareMarkOnDeliveryTest {
    @Test
    fun `a resolved file burns the intent`() {
        assertTrue(shouldMarkDelivered(1))
    }

    @Test
    fun `an empty resolve leaves the intent reusable`() {
        // copyToCache swallows IO failures and returns nothing. Marking
        // unconditionally turned a transient copy failure into a permanently
        // unrecoverable share — cost a rebuild to find on device.
        assertFalse(shouldMarkDelivered(0))
    }

    @Test
    fun `a multi-file share burns the intent once`() {
        assertTrue(shouldMarkDelivered(3))
    }
}

class ShareDeliveryMarkTest {
    @Test
    fun `a fresh share intent has not been delivered`() {
        assertFalse(isAlreadyDelivered(marked = false, flags = 0))
    }

    @Test
    fun `a marked intent is not resolved a second time`() {
        assertTrue(isAlreadyDelivered(marked = true, flags = 0))
    }

    @Test
    fun `relaunching from Recents does not re-deliver the share`() {
        assertTrue(
            isAlreadyDelivered(
                marked = false,
                flags = Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY,
            ),
        )
    }

    @Test
    fun `a task restored after process death does not re-deliver the share`() {
        // Measured on a Pixel 9 Pro Fold: kill the process, relaunch from
        // Recents, and the share was resolved and copied a second time —
        // neither the intent extra nor LAUNCHED_FROM_HISTORY survived.
        assertTrue(isAlreadyDelivered(marked = false, flags = 0, restoredTask = true))
    }

    @Test
    fun `a fresh launch is not treated as a restore`() {
        assertFalse(isAlreadyDelivered(marked = false, flags = 0, restoredTask = false))
    }

    @Test
    fun `unrelated intent flags do not suppress a real share`() {
        assertFalse(
            isAlreadyDelivered(
                marked = false,
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION,
            ),
        )
    }
}
