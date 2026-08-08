package com.example.hisabet

import android.os.Build
import com.google.firebase.pnv.FirebasePhoneNumberVerification
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Firebase Phone Number Verification (PNV) to Dart.
 *
 * PNV verifies the number of the SIM in the device by talking to the carrier,
 * so there is no SMS and no code for the user to type. Firebase ships it as an
 * Android library only — there is no FlutterFire plugin — hence this channel.
 *
 * Three methods:
 *  - `isAvailable`      cheap capability probe, so the UI never offers a path
 *                       the device cannot take.
 *  - `enableTestSession` dev only. Uses a console-issued token and a mock
 *                       number, which is how this can be exercised without a
 *                       supported carrier. Must run at most once per process.
 *  - `verify`           launches verification, returns the number and the
 *                       attestation token.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "hisabet/pnv"

        /** PNV needs API 26; below that the library is simply not offered. */
        const val MIN_SDK = Build.VERSION_CODES.O

        /**
         * `enableTestSession` throws if called twice on the same instance, and
         * the engine can be rebuilt (hot restart) while the process lives on,
         * so the guard has to outlive the activity.
         */
        var testSessionStarted = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(Build.VERSION.SDK_INT >= MIN_SDK)
                    "enableTestSession" -> enableTestSession(call.argument("token"), result)
                    "verify" -> verify(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun enableTestSession(token: String?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < MIN_SDK) {
            result.success(false)
            return
        }
        if (token.isNullOrBlank()) {
            result.error("no-token", "No PNV test token was supplied.", null)
            return
        }
        if (testSessionStarted) {
            // Already armed for this process — not an error, just a no-op.
            result.success(true)
            return
        }
        try {
            FirebasePhoneNumberVerification.getInstance().enableTestSession(token)
            testSessionStarted = true
            result.success(true)
        } catch (e: Exception) {
            result.error("test-session-failed", e.message, null)
        }
    }

    private fun verify(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < MIN_SDK) {
            result.error(
                "unsupported",
                "Phone verification over the network needs Android 8 or newer.",
                null,
            )
            return
        }

        try {
            FirebasePhoneNumberVerification.getInstance()
                .getVerifiedPhoneNumber(this)
                .addOnSuccessListener { response ->
                    result.success(
                        mapOf(
                            "phoneNumber" to response.getPhoneNumber(),
                            "token" to response.getToken(),
                        )
                    )
                }
                .addOnFailureListener { e ->
                    result.error("verification-failed", e.message, e::class.java.simpleName)
                }
        } catch (e: Exception) {
            result.error("verification-failed", e.message, null)
        }
    }
}
