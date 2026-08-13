package com.ventoux.paperlessgo

import android.content.Intent
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Regression coverage for [selectSource] — the action→source dispatch that decides
 * where a shared file's URI comes from. This exact mapping has silently dropped an
 * action type three separate times (share-intent fixes in 10411c1, 810f061, cade169),
 * each time shipping a "fix" for one action while another (most recently ACTION_VIEW
 * / "Open with") fell through to the `else -> emptyList()` branch with no test to
 * catch it.
 */
class SharePluginUriSelectionTest {
    @Test
    fun `ACTION_SEND selects EXTRA_STREAM`() {
        assertEquals(ShareSource.EXTRA_STREAM, selectSource(Intent.ACTION_SEND, null))
    }

    @Test
    fun `ACTION_SEND_MULTIPLE selects EXTRA_STREAM`() {
        assertEquals(ShareSource.EXTRA_STREAM, selectSource(Intent.ACTION_SEND_MULTIPLE, null))
    }

    @Test
    fun `ACTION_VIEW with content scheme selects INTENT_DATA`() {
        assertEquals(ShareSource.INTENT_DATA, selectSource(Intent.ACTION_VIEW, "content"))
    }

    @Test
    fun `ACTION_VIEW with file scheme selects INTENT_DATA`() {
        assertEquals(ShareSource.INTENT_DATA, selectSource(Intent.ACTION_VIEW, "file"))
    }

    @Test
    fun `ACTION_VIEW with paperlessgo scheme is ignored (widget deep link, not a file)`() {
        assertEquals(ShareSource.NONE, selectSource(Intent.ACTION_VIEW, "paperlessgo"))
    }

    @Test
    fun `ACTION_VIEW with null scheme is ignored`() {
        assertEquals(ShareSource.NONE, selectSource(Intent.ACTION_VIEW, null))
    }

    @Test
    fun `unrecognized action is ignored`() {
        assertEquals(ShareSource.NONE, selectSource(Intent.ACTION_MAIN, "content"))
    }

    @Test
    fun `null action is ignored`() {
        assertEquals(ShareSource.NONE, selectSource(null, "content"))
    }
}
