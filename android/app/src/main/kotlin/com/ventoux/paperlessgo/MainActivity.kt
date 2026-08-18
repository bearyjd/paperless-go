package com.ventoux.paperlessgo

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private lateinit var sharePlugin: SharePlugin

    /**
     * True when this Activity is being rebuilt for a task that already existed
     * — the process was killed and the user came back via Recents, so Android
     * restores the task along with the intent that originally started it.
     *
     * That restored intent is still a share intent, so without this the share
     * is resolved and delivered a second time: the file is re-copied to cache
     * and the user is dropped back into an upload flow they already finished
     * or dismissed. Verified on a Pixel 9 Pro Fold — neither an extra written
     * onto the intent nor FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY survives process
     * death, but savedInstanceState does, because it is exactly the signal
     * that this is a restore rather than a fresh launch.
     */
    private var isRestoredTask = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PdfRendererPlugin.register(flutterEngine)
        sharePlugin = SharePlugin(this) { isRestoredTask }
        sharePlugin.register(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        isRestoredTask = savedInstanceState != null
        stripDataFromShareIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        // A genuinely new intent, so this is no longer a restore — a share
        // arriving now must be delivered even though the task was resumed.
        isRestoredTask = false
        stripDataFromShareIntent(intent)
        super.onNewIntent(intent)
        // Activity.intent otherwise still points at whatever launched the process,
        // so a later getInitialShare() (SharePlugin reads activity.intent) resolves
        // the *stale* intent and returns zero files for a share that just arrived.
        setIntent(intent)
        sharePlugin.onNewIntent(intent)
    }

    /**
     * Some sharing apps (e.g. GrapheneOS PDF Viewer) set Intent.data on a
     * SEND/SEND_MULTIPLE intent in addition to the standard EXTRA_STREAM.
     * Flutter's embedding treats any non-null Intent.data as a deep-link
     * route to push automatically, racing SharePlugin's own handling and
     * surfacing the raw content:// URI as an unmatched route ("Page not
     * found"). SharePlugin reads files from EXTRA_STREAM/ClipData, never
     * from Intent.data, so clearing it here is safe and only affects
     * share intents — the paperlessgo:// widget deep links (ACTION_VIEW)
     * are untouched.
     */
    private fun stripDataFromShareIntent(intent: Intent) {
        if (intent.action == Intent.ACTION_SEND || intent.action == Intent.ACTION_SEND_MULTIPLE) {
            intent.data = null
        }
    }
}
