package com.yourdomain.adaptive_image_picker

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.concurrent.Executors

/** AdaptiveImagePickerPlugin */
class AdaptiveImagePickerPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    private var pendingResult: Result? = null
    private var currentCameraFile: File? = null

    private val executor = Executors.newSingleThreadExecutor()

    companion object {
        private const val REQUEST_CODE_PICK_IMAGES = 1001
        private const val REQUEST_CODE_TAKE_PHOTO = 1002
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "adaptive_image_picker")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "pickImages" -> {
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity is not available to pick images.", null)
                    return
                }
                if (pendingResult != null) {
                    result.error("ALREADY_ACTIVE", "An image picking session is already in progress.", null)
                    return
                }

                pendingResult = result
                val isMultiple = call.argument<Boolean>("isMultiple") ?: false
                val maxCount = call.argument<Int>("maxCount") ?: 1
                val mediaType = call.argument<String>("mediaType") ?: "image"

                launchPhotoPicker(isMultiple, maxCount, mediaType)
            }
            "takePhoto" -> {
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity is not available to take photo.", null)
                    return
                }
                if (pendingResult != null) {
                    result.error("ALREADY_ACTIVE", "A media session is already in progress.", null)
                    return
                }

                pendingResult = result
                launchCamera()
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun launchPhotoPicker(isMultiple: Boolean, maxCount: Int, mediaType: String) {
        val currentAct = activity ?: return

        try {
            // Android 13+ (API 33+) native Photo Picker
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val intent = Intent(MediaStore.ACTION_PICK_IMAGES)
                when (mediaType) {
                    "video" -> intent.type = "video/*"
                    "all" -> intent.type = "*/*"
                    else -> intent.type = "image/*"
                }

                if (isMultiple && maxCount > 1) {
                    intent.putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, maxCount)
                }
                currentAct.startActivityForResult(intent, REQUEST_CODE_PICK_IMAGES)
            } else {
                // Fallback for older Android versions
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    when (mediaType) {
                        "video" -> type = "video/*"
                        "all" -> {
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "video/*"))
                        }
                        else -> type = "image/*"
                    }
                    if (isMultiple && maxCount > 1) {
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                    }
                }
                currentAct.startActivityForResult(
                    Intent.createChooser(intent, "Select Media"),
                    REQUEST_CODE_PICK_IMAGES
                )
            }
        } catch (e: Exception) {
            pendingResult?.error("PICK_FAILED", "Failed to launch photo picker: ${e.message}", null)
            pendingResult = null
        }
    }

    private fun launchCamera() {
        val currentAct = activity ?: return
        val currentCtx = context ?: return

        try {
            val cameraDir = File(currentCtx.cacheDir, "adaptive_camera")
            if (!cameraDir.exists()) cameraDir.mkdirs()

            val fileName = "photo_${System.currentTimeMillis()}.jpg"
            val photoFile = File(cameraDir, fileName)
            currentCameraFile = photoFile

            val authority = "${currentCtx.packageName}.adaptive_image_picker.fileprovider"
            val photoUri: Uri = FileProvider.getUriForFile(currentCtx, authority, photoFile)

            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, photoUri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            }

            currentAct.startActivityForResult(intent, REQUEST_CODE_TAKE_PHOTO)
        } catch (e: Exception) {
            pendingResult?.error("CAMERA_FAILED", "Failed to launch camera: ${e.message}", null)
            pendingResult = null
            currentCameraFile = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == REQUEST_CODE_PICK_IMAGES) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uris = mutableListOf<Uri>()
                val clipData = data.clipData
                if (clipData != null) {
                    for (i in 0 until clipData.itemCount) {
                        uris.add(clipData.getItemAt(i).uri)
                    }
                } else if (data.data != null) {
                    uris.add(data.data!!)
                }

                executor.execute {
                    val resultList = mutableListOf<Map<String, Any?>>()
                    val ctx = context
                    if (ctx != null) {
                        for (uri in uris) {
                            val fileInfo = copyUriToCacheAndGetInfo(ctx, uri)
                            if (fileInfo != null) {
                                resultList.add(fileInfo)
                            }
                        }
                    }

                    activity?.runOnUiThread {
                        pendingResult?.success(resultList)
                        pendingResult = null
                    }
                }
            } else {
                pendingResult?.success(emptyList<Map<String, Any?>>())
                pendingResult = null
            }
            return true
        }

        if (requestCode == REQUEST_CODE_TAKE_PHOTO) {
            if (resultCode == Activity.RESULT_OK && currentCameraFile != null && currentCameraFile!!.exists() && currentCameraFile!!.length() > 0) {
                val file = currentCameraFile!!
                val fileInfo = mapOf<String, Any?>(
                    "path" to file.absolutePath,
                    "name" to file.name,
                    "size" to file.length(),
                    "mimeType" to "image/jpeg",
                    "lastModified" to file.lastModified()
                )
                pendingResult?.success(fileInfo)
            } else {
                currentCameraFile?.delete()
                pendingResult?.success(null)
            }
            pendingResult = null
            currentCameraFile = null
            return true
        }

        return false
    }

    private fun copyUriToCacheAndGetInfo(ctx: Context, uri: Uri): Map<String, Any?>? {
        try {
            val contentResolver = ctx.contentResolver
            val mimeType = contentResolver.getType(uri) ?: "image/jpeg"

            var displayName = "picked_image_${System.currentTimeMillis()}"
            var size = 0L

            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (nameIndex != -1) {
                        displayName = cursor.getString(nameIndex) ?: displayName
                    }
                    if (sizeIndex != -1) {
                        size = cursor.getLong(sizeIndex)
                    }
                }
            }

            val cacheDir = File(ctx.cacheDir, "adaptive_picker")
            if (!cacheDir.exists()) cacheDir.mkdirs()

            val destinationFile = File(cacheDir, displayName)
            var inputStream: InputStream? = null
            var outputStream: FileOutputStream? = null

            try {
                inputStream = contentResolver.openInputStream(uri)
                outputStream = FileOutputStream(destinationFile)
                if (inputStream != null) {
                    val buffer = ByteArray(8192)
                    var bytesRead: Int
                    while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                        outputStream.write(buffer, 0, bytesRead)
                    }
                }
            } finally {
                inputStream?.close()
                outputStream?.close()
            }

            val finalSize = if (size > 0) size else destinationFile.length()

            return mapOf(
                "path" to destinationFile.absolutePath,
                "name" to displayName,
                "size" to finalSize,
                "mimeType" to mimeType,
                "lastModified" to destinationFile.lastModified()
            )
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activity = null
        activityBinding = null
    }
}
