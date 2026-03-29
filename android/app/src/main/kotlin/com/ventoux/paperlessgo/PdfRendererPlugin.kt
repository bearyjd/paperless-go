package com.ventoux.paperlessgo

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class PdfRendererPlugin {
    companion object {
        private const val CHANNEL = "com.ventoux.paperlessgo/pdf_renderer"

        fun register(flutterEngine: FlutterEngine) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "renderPages" -> {
                            val filePath = call.argument<String>("filePath")
                            val scale = call.argument<Double>("scale") ?: 1.0
                            if (filePath == null) {
                                result.error("INVALID_ARGS", "filePath required", null)
                                return@setMethodCallHandler
                            }
                            try {
                                val pages = renderPages(filePath, scale.toFloat())
                                result.success(pages)
                            } catch (e: Exception) {
                                result.error("RENDER_ERROR", e.message, null)
                            }
                        }
                        "getPageCount" -> {
                            val filePath = call.argument<String>("filePath")
                            if (filePath == null) {
                                result.error("INVALID_ARGS", "filePath required", null)
                                return@setMethodCallHandler
                            }
                            try {
                                val count = getPageCount(filePath)
                                result.success(count)
                            } catch (e: Exception) {
                                result.error("RENDER_ERROR", e.message, null)
                            }
                        }
                        else -> result.notImplemented()
                    }
                }
        }

        private fun getPageCount(filePath: String): Int {
            val file = File(filePath)
            val fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(fd)
            val count = renderer.pageCount
            renderer.close()
            fd.close()
            return count
        }

        private fun renderPages(filePath: String, scale: Float): List<ByteArray> {
            val file = File(filePath)
            val fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(fd)
            val pages = mutableListOf<ByteArray>()

            for (i in 0 until renderer.pageCount) {
                val page = renderer.openPage(i)
                val width = (page.width * scale).toInt()
                val height = (page.height * scale).toInt()
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                bitmap.eraseColor(Color.WHITE)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                page.close()

                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                pages.add(stream.toByteArray())
                bitmap.recycle()
            }

            renderer.close()
            fd.close()
            return pages
        }
    }
}
