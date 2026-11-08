package mx.barrio.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Notificaciones nativas: sin dependencia nueva para una sola notificación simple.
class MainActivity : FlutterActivity() {
    private val canalAviso = "pedidos"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "barrio/avisos")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "permiso" -> {
                        if (Build.VERSION.SDK_INT >= 33 &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
                        ) {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 41)
                        }
                        result.success(null)
                    }
                    "mostrar" -> {
                        mostrar(
                            call.argument<Int>("id") ?: 0,
                            call.argument<String>("titulo") ?: "Barrio",
                            call.argument<String>("texto") ?: "",
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun mostrar(id: Int, titulo: String, texto: String) {
        val manager = getSystemService(NotificationManager::class.java)
        val abrir = PendingIntent.getActivity(
            this, 0, packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(canalAviso, "Tus pedidos", NotificationManager.IMPORTANCE_HIGH),
            )
            Notification.Builder(this, canalAviso)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_HIGH)
        }
        manager.notify(
            id,
            builder.setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(titulo)
                .setContentText(texto)
                .setContentIntent(abrir)
                .setAutoCancel(true)
                .build(),
        )
    }
}
