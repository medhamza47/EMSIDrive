package ma.emsi.emsidrive.emsidrive_mobile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import androidx.exifinterface.media.ExifInterface
import com.paddle.ocr.EngineConfig
import com.paddle.ocr.PaddleOCR
import com.paddle.ocr.PaddleOCRConfig
import com.paddle.ocr.util.OpenCVUtils
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.ByteArrayInputStream
import java.io.File
import kotlin.math.max
import kotlin.math.roundToInt

/** Owns one CPU inference job. Images and OCR output stay on the device. */
class LocalScheduleOcr(private val context: Context, messenger: BinaryMessenger) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var running: Job? = null
    private val channel = MethodChannel(messenger, "emsidrive/local_schedule_ocr")

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "cancel" -> { running?.cancel(); result.success(null) }
                "analyze" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null || bytes.isEmpty() || bytes.size > 8 * 1024 * 1024) {
                        result.error("LOCAL_OCR_FILE", "Invalid timetable file", null)
                    } else if (running?.isCompleted == false) {
                        result.error("LOCAL_OCR_BUSY", "An analysis is already running", null)
                    } else {
                        running = scope.launch {
                            try {
                                result.success(analyzeDocument(context, bytes))
                            } catch (_: CancellationException) {
                                result.error("LOCAL_OCR_CANCELLED", "Analysis cancelled", null)
                            } catch (_: OutOfMemoryError) {
                                result.error("LOCAL_OCR_MEMORY", "Use a smaller timetable photo", null)
                            } catch (_: LinkageError) {
                                result.error("LOCAL_OCR_FAILED", "The OCR runtime could not be loaded", null)
                            } catch (error: Exception) {
                                val code = if (error is DocumentException) error.code else "LOCAL_OCR_FAILED"
                                result.error(code, "Unable to read the timetable on this phone", null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun close() { channel.setMethodCallHandler(null); scope.cancel() }

    companion object {
        /** Also exercised on the physical device by the instrumentation test. */
        suspend fun analyzeDocument(context: Context, bytes: ByteArray): Map<String, Any> = withContext(Dispatchers.Default) {
            val started = System.nanoTime()
            check(OpenCVUtils.init(context)) { "OpenCV could not be initialized" }
            val engine = PaddleOCR.create(context, PaddleOCRConfig(
                detLimitSideLen = 1600, detLimitType = "max", detMaxSideLimit = 2400,
                recScoreThresh = 0.25f, recBatchSize = 1,
            ), EngineConfig(numThreads = 2))
            val pages = mutableListOf<Map<String, Any>>()
            try {
                suspend fun read(bitmap: Bitmap) {
                    try {
                        currentCoroutineContext().ensureActive()
                        val inference = engine.recognize(bitmap)
                        currentCoroutineContext().ensureActive()
                        val lines = inference.results.map { line ->
                            mapOf("text" to line.text, "confidence" to line.confidence.toDouble(),
                                "left" to line.box.points.minOf { it.x }.toDouble(),
                                "right" to line.box.points.maxOf { it.x }.toDouble(),
                                "top" to line.box.points.minOf { it.y }.toDouble(),
                                "bottom" to line.box.points.maxOf { it.y }.toDouble())
                        }
                        pages.add(mapOf("width" to bitmap.width, "height" to bitmap.height,
                            "lines" to lines, "grid" to LocalTimetableGridDetector().scan(bitmap)))
                    } finally { bitmap.recycle() }
                }
                if (bytes.take(5).toByteArray().contentEquals("%PDF-".toByteArray())) {
                    val temporary = File.createTempFile("local-timetable-", ".pdf", context.cacheDir)
                    try {
                        temporary.writeBytes(bytes)
                        ParcelFileDescriptor.open(temporary, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                            PdfRenderer(descriptor).use { renderer ->
                                if (renderer.pageCount !in 1..3) throw DocumentException("LOCAL_OCR_PDF_PAGES")
                                for (index in 0 until renderer.pageCount) {
                                    currentCoroutineContext().ensureActive()
                                    renderer.openPage(index).use { page ->
                                        val scale = 2200.0 / max(page.width, page.height)
                                        val bitmap = Bitmap.createBitmap(max(1, (page.width * scale).roundToInt()),
                                            max(1, (page.height * scale).roundToInt()), Bitmap.Config.ARGB_8888)
                                        bitmap.eraseColor(Color.WHITE)
                                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                        read(bitmap)
                                    }
                                }
                            }
                        }
                    } finally { temporary.delete() }
                } else {
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
                    if (bounds.outWidth <= 0 || bounds.outHeight <= 0 ||
                        bounds.outWidth.toLong() * bounds.outHeight > 25_000_000) throw DocumentException("LOCAL_OCR_FILE")
                    val options = BitmapFactory.Options().apply {
                        inSampleSize = 1
                        while (max(bounds.outWidth, bounds.outHeight) / inSampleSize > 3000) inSampleSize *= 2
                    }
                    var bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
                        ?: throw DocumentException("LOCAL_OCR_FILE")
                    val orientation = ExifInterface(ByteArrayInputStream(bytes))
                        .getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
                    val transform = Matrix()
                    when (orientation) {
                        ExifInterface.ORIENTATION_ROTATE_90 -> transform.postRotate(90f)
                        ExifInterface.ORIENTATION_ROTATE_180 -> transform.postRotate(180f)
                        ExifInterface.ORIENTATION_ROTATE_270 -> transform.postRotate(270f)
                        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> transform.postScale(-1f, 1f)
                        ExifInterface.ORIENTATION_FLIP_VERTICAL -> transform.postScale(1f, -1f)
                        ExifInterface.ORIENTATION_TRANSPOSE -> { transform.postRotate(90f); transform.postScale(-1f, 1f) }
                        ExifInterface.ORIENTATION_TRANSVERSE -> { transform.postRotate(270f); transform.postScale(-1f, 1f) }
                    }
                    if (!transform.isIdentity) {
                        val oriented = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, transform, true)
                        if (oriented !== bitmap) bitmap.recycle()
                        bitmap = oriented
                    }
                    if (max(bitmap.width, bitmap.height) > 2200) {
                        val scale = 2200.0 / max(bitmap.width, bitmap.height)
                        val scaled = Bitmap.createScaledBitmap(bitmap, max(1, (bitmap.width * scale).roundToInt()),
                            max(1, (bitmap.height * scale).roundToInt()), true)
                        if (scaled !== bitmap) bitmap.recycle()
                        bitmap = scaled
                    }
                    read(bitmap)
                }
            } finally { withContext(NonCancellable) { engine.release() } }
            mapOf("model" to "PP-OCRv6 Small", "pages" to pages,
                "elapsedMs" to (System.nanoTime() - started) / 1_000_000)
        }
    }

    private class DocumentException(val code: String) : Exception(code)
}
