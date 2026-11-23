package ma.emsi.emsidrive.emsidrive_mobile

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Exercises the bundled ONNX models on the actual Android CPU. */
@RunWith(AndroidJUnit4::class)
class LocalScheduleOcrTest {
    @Test fun readsTimetablePhotoWithBundledModels(): Unit = runBlocking {
        checkFixture("sample-timetable.png", "phone-ocr-photo.json", listOf("lundi", "mardi", "vendredi"))
    }

    @Test fun readsPdfAndDetectsMergedCells(): Unit = runBlocking {
        val result = checkFixture("timetable-merged.pdf", "phone-ocr-merged.json", listOf("lundi", "mardi", "mercredi", "jeudi"))
        val pages = result["pages"] as List<*>
        val grid = (pages.first() as Map<*,*>)["grid"] as Map<*,*>
        val rows = grid["rows"] as List<*>
        assertTrue("A double lesson must keep its physical span", rows.any { row ->
            ((row as Map<*,*>)["cells"] as List<*>).any { cell ->
                val c = cell as Map<*,*>
                (c["last"] as Number).toInt() > (c["first"] as Number).toInt()
            }
        })
    }

    private suspend fun checkFixture(name: String, output: String, expected: List<String>): Map<String,Any> {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val bytes = instrumentation.context.assets.open(name).use { it.readBytes() }
        val result = LocalScheduleOcr.analyzeDocument(instrumentation.targetContext, bytes)
        val page = (result["pages"] as List<*>).first() as Map<*,*>
        val text = (page["lines"] as List<*>).joinToString(" ") { (it as Map<*,*>)["text"].toString() }.lowercase()
        expected.forEach { word -> assertTrue("Missing $word in $text", text.contains(word)) }
        assertTrue("Time headers were not read: $text", text.contains("08:30"))
        assertTrue("No physical grid found", (page["grid"] as Map<*,*>).isNotEmpty())
        File(instrumentation.targetContext.cacheDir, output).writeText(JSONObject(result).toString())
        return result
    }
}
