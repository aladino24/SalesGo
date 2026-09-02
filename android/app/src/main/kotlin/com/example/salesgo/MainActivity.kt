package com.example.salesgo

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val updateChannel = "salesgo/app_update"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updateChannel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "installedApp" -> result.success(installedApp())
                        "fileMd5" -> {
                            val path = call.argument<String>("path")
                            if (path.isNullOrBlank()) {
                                result.error("INVALID_PATH", "Path APK wajib diisi.", null)
                            } else {
                                result.success(md5(File(path)))
                            }
                        }
                        "installApk" -> {
                            val path = call.argument<String>("path")
                            if (path.isNullOrBlank() || !File(path).isFile) {
                                result.error("APK_NOT_FOUND", "File APK tidak ditemukan.", null)
                            } else {
                                result.success(installApk(File(path)))
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("APP_UPDATE_ERROR", error.message, null)
                }
            }
    }

    private fun installedApp(): Map<String, Any> {
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0)
        }
        val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) info.longVersionCode else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
        return mapOf(
            "versionName" to (info.versionName ?: ""),
            "versionCode" to versionCode,
            // Hanya APK aplikasi sendiri yang dihitung. Nilai dipakai backend
            // untuk membandingkan artefak rilis, bukan sebagai secret keamanan.
            "md5" to md5(File(applicationInfo.sourceDir)),
        )
    }

    private fun md5(file: File): String {
        val digest = MessageDigest.getInstance("MD5")
        FileInputStream(file).use { input ->
            val buffer = ByteArray(8192)
            while (true) {
                val count = input.read(buffer)
                if (count <= 0) break
                digest.update(buffer, 0, count)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private fun installApk(apk: File): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
            startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
            return "permission_required"
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", apk)
        startActivity(Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
        return "installer_opened"
    }
}
