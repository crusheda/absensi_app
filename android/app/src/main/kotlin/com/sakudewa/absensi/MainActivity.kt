package com.sakudewa.absensi

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sakudewa.absensi/integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkIntegrity") {
                checkIntegrity(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkIntegrity(result: MethodChannel.Result) {
        val integrityManager = IntegrityManagerFactory.create(this)

        val nonce = "random-string-${System.currentTimeMillis()}" // sebaiknya digenerate di server

        val request = IntegrityTokenRequest.builder()
            .setNonce(nonce)
            .build()

        integrityManager.requestIntegrityToken(request)
            .addOnSuccessListener { response ->
                val token = response.token()
                result.success(token) // kirim balik ke Flutter
            }
            .addOnFailureListener { e ->
                result.error("INTEGRITY_ERROR", e.message, null)
            }
    }
}
