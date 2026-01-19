package com.komjirak.stribe

import android.content.ContentResolver
import android.database.ContentObserver
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

class MainActivity : FlutterActivity() {
    private val VISION_CHANNEL = "com.komjirak.stribe/vision"
    private val EVENT_CHANNEL = "com.komjirak.stribe/screenshot_detection"

    private var eventSink: EventChannel.EventSink? = null
    private var screenshotObserver: ContentObserver? = null
    private var lastProcessedImageId: Long = -1
    private var isMonitoring = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VISION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startScreenshotMonitoring" -> startMonitoring(result)
                "stopScreenshotMonitoring" -> stopMonitoring(result)
                "getLastScreenshotAnalysis" -> getLastScreenshot(result)
                "analyzeImage" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        analyzeImage(path, result)
                    } else {
                        result.error("INVALID_ARGS", "Path argument missing", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Event Channel for screenshot detection stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun startMonitoring(result: MethodChannel.Result) {
        if (isMonitoring) {
            result.success(true)
            return
        }

        // Get the latest image ID to avoid processing old images
        updateLastProcessedImageId()

        screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                Log.d("ScreenshotDetection", "MediaStore changed: $uri")
                checkForNewScreenshot()
            }
        }

        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            screenshotObserver!!
        )

        isMonitoring = true
        result.success(true)
    }

    private fun stopMonitoring(result: MethodChannel.Result) {
        screenshotObserver?.let {
            contentResolver.unregisterContentObserver(it)
            screenshotObserver = null
        }
        isMonitoring = false
        result.success(true)
    }

    private fun updateLastProcessedImageId() {
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                lastProcessedImageId = cursor.getLong(idColumn)
            }
        }
    }

    private fun checkForNewScreenshot() {
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_ADDED,
            MediaStore.Images.Media.DISPLAY_NAME
        )
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
                val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)

                val imageId = cursor.getLong(idColumn)
                val imagePath = cursor.getString(dataColumn)
                val dateAdded = cursor.getLong(dateColumn)
                val displayName = cursor.getString(nameColumn)

                // Check if this is a new image
                if (imageId != lastProcessedImageId) {
                    lastProcessedImageId = imageId

                    // Check if it's a screenshot (common patterns)
                    val isScreenshot = displayName.lowercase().contains("screenshot") ||
                            imagePath.lowercase().contains("screenshot") ||
                            imagePath.lowercase().contains("screen")

                    Log.d("ScreenshotDetection", "New image detected: $displayName, isScreenshot: $isScreenshot")

                    // Process and send to Flutter
                    processNewImage(imagePath, dateAdded)
                }
            }
        }
    }

    private fun processNewImage(imagePath: String, dateAdded: Long) {
        try {
            // Copy to app's temp directory
            val tempPath = copyToTemp(imagePath)
            if (tempPath == null) {
                Log.e("ScreenshotDetection", "Failed to copy image to temp")
                return
            }

            // Format date
            val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            val dateStr = dateFormat.format(Date(dateAdded * 1000))

            // Basic category detection from path
            val category = detectCategory(imagePath)
            val tags = extractTags(imagePath)

            val result = mapOf(
                "imagePath" to tempPath,
                "ocrText" to "", // OCR will be handled by Flutter side if needed
                "date" to dateStr,
                "suggestedTags" to tags,
                "suggestedCategory" to category,
                "assetId" to imagePath
            )

            // Send to Flutter
            Handler(Looper.getMainLooper()).post {
                eventSink?.success(result)
            }

        } catch (e: Exception) {
            Log.e("ScreenshotDetection", "Error processing image", e)
        }
    }

    private fun copyToTemp(sourcePath: String): String? {
        return try {
            val sourceFile = File(sourcePath)
            if (!sourceFile.exists()) return null

            val tempDir = cacheDir
            val fileName = "capture_${System.currentTimeMillis()}.jpg"
            val destFile = File(tempDir, fileName)

            sourceFile.inputStream().use { input ->
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            }
            destFile.absolutePath
        } catch (e: Exception) {
            Log.e("ScreenshotDetection", "Failed to copy file", e)
            null
        }
    }

    private fun detectCategory(path: String): String {
        val lowerPath = path.lowercase()
        return when {
            lowerPath.contains("shopping") || lowerPath.contains("store") -> "Shopping"
            lowerPath.contains("food") || lowerPath.contains("recipe") -> "Food"
            lowerPath.contains("work") || lowerPath.contains("office") -> "Work"
            else -> "Inbox"
        }
    }

    private fun extractTags(path: String): List<String> {
        val tags = mutableListOf<String>()
        val lowerPath = path.lowercase()

        if (lowerPath.contains("screenshot")) tags.add("Screenshot")
        if (lowerPath.contains("camera")) tags.add("Photo")

        if (tags.isEmpty()) tags.add("Imported")

        return tags
    }

    private fun getLastScreenshot(result: MethodChannel.Result) {
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_ADDED
        )
        val sortOrder = "${MediaStore.Images.Media.DATE_ADDED} DESC"

        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            sortOrder
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)

                val imagePath = cursor.getString(dataColumn)
                val dateAdded = cursor.getLong(dateColumn)

                val tempPath = copyToTemp(imagePath)
                if (tempPath != null) {
                    val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
                    val dateStr = dateFormat.format(Date(dateAdded * 1000))

                    result.success(mapOf(
                        "imagePath" to tempPath,
                        "ocrText" to "",
                        "date" to dateStr,
                        "suggestedTags" to extractTags(imagePath),
                        "suggestedCategory" to detectCategory(imagePath)
                    ))
                } else {
                    result.error("LOAD_FAILED", "Failed to load image", null)
                }
            } else {
                result.error("NO_SCREENSHOT", "No images found", null)
            }
        } ?: result.error("QUERY_FAILED", "Failed to query media store", null)
    }

    private fun analyzeImage(path: String, result: MethodChannel.Result) {
        val tempPath = copyToTemp(path) ?: path

        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
        val dateStr = dateFormat.format(Date())

        result.success(mapOf(
            "imagePath" to tempPath,
            "ocrText" to "",
            "date" to dateStr,
            "suggestedTags" to extractTags(path),
            "suggestedCategory" to detectCategory(path)
        ))
    }

    override fun onDestroy() {
        screenshotObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        super.onDestroy()
    }
}
