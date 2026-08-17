package com.ventoux.paperlessgo

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Parcelable
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream

/**
 * Which part of an Intent carries the shared file, decided by [selectSource] from
 * the intent's action and Intent.data scheme alone. Kept as a pure decision separate
 * from the actual (Android-only) extraction so the action→source mapping — the exact
 * class of bug this file has shipped three times (share-intent fixes in 10411c1,
 * 810f061, cade169, each missing a different action type) — has a plain JUnit
 * regression test with no Android runtime required.
 */
internal enum class ShareSource { EXTRA_STREAM, INTENT_DATA, NONE }

/**
 * Decides where to read a shared file's URI(s) from for a given intent action.
 *
 * - SEND / SEND_MULTIPLE: EXTRA_STREAM (share-sheet flow).
 * - VIEW: Intent.data, but ONLY for content/file schemes — "Open with" from a file
 *   manager (see the ACTION_VIEW intent-filter in AndroidManifest.xml) uses this
 *   action, but so does the paperlessgo:// home-screen-widget deep link, which is
 *   NOT a file and must not be misread as one.
 * - anything else: no file.
 */
internal fun selectSource(action: String?, dataScheme: String?): ShareSource = when (action) {
    Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE -> ShareSource.EXTRA_STREAM
    Intent.ACTION_VIEW -> if (dataScheme == "content" || dataScheme == "file") {
        ShareSource.INTENT_DATA
    } else {
        ShareSource.NONE
    }
    else -> ShareSource.NONE
}

/**
 * Whether a share intent has already produced a delivery, from the two signals
 * that survive Activity/engine recreation.
 *
 * MainActivity calls setIntent() so activity.intent stays current for
 * getInitialShare — which also means the share intent lives on in the task
 * record. Without a guard it gets resolved again (copying a second file into
 * cache and re-pushing the user into the upload screen) by any later
 * getInitialShare: a relaunch from Recents, or a recreation that builds a fresh
 * SharePlugin. Instance state cannot cover that; a mark on the intent survives
 * exactly as long as the intent does, and LAUNCHED_FROM_HISTORY catches an
 * intent consumed before the mark existed.
 */
internal fun isAlreadyDelivered(marked: Boolean, flags: Int): Boolean =
    marked || (flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0

/**
 * Holds resolved shares until Dart's EventChannel listener attaches.
 *
 * Shares can be resolved before Flutter is listening — an `eventSink?.success`
 * on a null sink drops the file with no trace, which is exactly how a share
 * that copied successfully still vanished. Buffered payloads replay in arrival
 * order on [attach]. A list, not a single slot: two shares can arrive back to
 * back while the engine boots, and each has already been copied to cache, so
 * overwriting would strand one on disk.
 */
internal class ShareDeliveryBuffer {
    private var sink: ((String) -> Unit)? = null
    private val pending = mutableListOf<String>()

    val bufferedCount: Int get() = pending.size

    fun deliver(payload: String) {
        val current = sink
        if (current != null) current(payload) else pending.add(payload)
    }

    fun attach(listener: (String) -> Unit) {
        sink = listener
        if (pending.isEmpty()) return
        pending.forEach(listener)
        pending.clear()
    }

    fun detach() {
        sink = null
    }
}

/**
 * Resolves shared files by reading their bytes directly via ContentResolver
 * and copying them to app cache. This exists because receive_sharing_intent's
 * FileDirectory.getAbsolutePath() resolves content:// URIs by translating them
 * into legacy content://downloads/public_downloads/<id> lookups, which throws
 * "Unknown URI" for modern SAF DocumentsProvider URIs (e.g. anything shared
 * via a Downloads/Files picker) — the file silently never reaches Dart.
 * ContentResolver.openInputStream() works for any content:// URI the intent
 * already granted read access to, regardless of provider.
 *
 * Any app can fire an implicit ACTION_VIEW at this activity (it's exported with
 * a BROWSABLE intent-filter) — that's the mechanism "Open with" relies on.
 * Android's URI-grant permission model is the trust boundary, not this code;
 * a URI without a valid grant fails in copyToCache() (caught, returns null),
 * it doesn't bypass anything.
 */
class SharePlugin(private val activity: Activity) {
    private val deliveries = ShareDeliveryBuffer()

    companion object {
        private const val TAG = "PaperlessShare"
        private const val METHOD_CHANNEL = "com.ventoux.paperlessgo/share"
        private const val EVENT_CHANNEL = "com.ventoux.paperlessgo/share_stream"
        private const val EXTRA_DELIVERED = "com.ventoux.paperlessgo.SHARE_DELIVERED"
    }

    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> {
                        val current = activity.intent
                        val files = if (current == null || wasDelivered(current)) {
                            Log.d(TAG, "getInitialShare: intent already delivered, skipping")
                            JSONArray()
                        } else {
                            // Marked only on a non-empty result: copyToCache
                            // swallows IO failures and returns nothing, and
                            // burning the intent on a transient failure would
                            // make the share unrecoverable. Re-resolving a
                            // genuinely empty intent costs nothing.
                            resolveIntent(current).also {
                                if (it.length() > 0) markDelivered(current)
                            }
                        }
                        result.success(files.toString())
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Log.d(TAG, "onListen: replaying ${deliveries.bufferedCount} buffered share(s)")
                    deliveries.attach { events.success(it) }
                }

                override fun onCancel(arguments: Any?) {
                    deliveries.detach()
                }
            })
    }

    fun onNewIntent(intent: Intent) {
        Log.d(TAG, "onNewIntent: action=${intent.action} data=${intent.data} type=${intent.type}")
        if (wasDelivered(intent)) {
            Log.d(TAG, "onNewIntent: intent already delivered, skipping")
            return
        }
        val files = resolveIntent(intent)
        Log.d(TAG, "onNewIntent: resolved ${files.length()} file(s)")
        // See getInitialShare: an empty result means nothing was delivered, so
        // the intent stays open rather than being burned on a failed copy.
        if (files.length() == 0) return
        markDelivered(intent)

        deliveries.deliver(files.toString())
    }

    private fun wasDelivered(intent: Intent): Boolean = isAlreadyDelivered(
        marked = intent.getBooleanExtra(EXTRA_DELIVERED, false),
        flags = intent.flags,
    )

    private fun markDelivered(intent: Intent) {
        intent.putExtra(EXTRA_DELIVERED, true)
    }

    private fun resolveIntent(intent: Intent?): JSONArray {
        if (intent == null) return JSONArray()
        val uris: List<Uri> = when (selectSource(intent.action, intent.data?.scheme)) {
            ShareSource.EXTRA_STREAM -> when (intent.action) {
                Intent.ACTION_SEND ->
                    parcelableExtra<Uri>(intent, Intent.EXTRA_STREAM)?.let { listOf(it) } ?: emptyList()
                Intent.ACTION_SEND_MULTIPLE ->
                    parcelableArrayListExtra<Uri>(intent, Intent.EXTRA_STREAM) ?: emptyList()
                else -> emptyList()
            }
            ShareSource.INTENT_DATA -> intent.data?.let { listOf(it) } ?: emptyList()
            ShareSource.NONE -> emptyList()
        }
        Log.d(TAG, "resolveIntent: action=${intent.action} extracted ${uris.size} uri(s): $uris")

        val results = JSONArray()
        for (uri in uris) {
            copyToCache(uri, intent.type)?.let { results.put(it) }
        }
        return results
    }

    private fun copyToCache(uri: Uri, intentMimeType: String?): JSONObject? {
        return try {
            val resolver = activity.contentResolver
            val displayName = queryDisplayName(uri) ?: "shared_${System.currentTimeMillis()}"
            val mimeType = intentMimeType ?: resolver.getType(uri)
            val targetFile = File(activity.cacheDir, "share_${System.currentTimeMillis()}_$displayName")
            Log.d(TAG, "copyToCache: uri=$uri displayName=$displayName mimeType=$mimeType target=${targetFile.absolutePath}")
            val copied = resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(targetFile).use { output -> input.copyTo(output) }
                true
            } ?: false
            Log.d(TAG, "copyToCache: copied=$copied exists=${targetFile.exists()} size=${targetFile.length()}")
            if (!copied) return null

            JSONObject()
                .put("path", targetFile.absolutePath)
                .put("filename", displayName)
                .put("mimeType", mimeType)
        } catch (e: Exception) {
            Log.e(TAG, "copyToCache failed for uri=$uri: ${e.javaClass.simpleName}: ${e.message}", e)
            null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme != "content") return uri.lastPathSegment
        return activity.contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (!cursor.moveToFirst()) return@use null
                val idx = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) cursor.getString(idx) else null
            }
    }

    @Suppress("DEPRECATION")
    private inline fun <reified T : Parcelable> parcelableExtra(intent: Intent, key: String): T? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(key, T::class.java)
        } else {
            intent.getParcelableExtra(key) as? T
        }

    @Suppress("DEPRECATION")
    private inline fun <reified T : Parcelable> parcelableArrayListExtra(
        intent: Intent,
        key: String,
    ): ArrayList<T>? =
        if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableArrayListExtra(key, T::class.java)
        } else {
            intent.getParcelableArrayListExtra(key)
        }
}
