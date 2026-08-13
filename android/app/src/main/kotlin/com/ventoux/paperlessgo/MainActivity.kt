package com.ventoux.paperlessgo

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private lateinit var sharePlugin: SharePlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PdfRendererPlugin.register(flutterEngine)
        sharePlugin = SharePlugin(this)
        sharePlugin.register(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        stripDataFromShareIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        stripDataFromShareIntent(intent)
        super.onNewIntent(intent)
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
