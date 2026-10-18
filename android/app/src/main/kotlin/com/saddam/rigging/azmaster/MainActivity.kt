package com.saddam.rigging.azmaster

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var pendingLocation: LocationListener? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingTimeout: Runnable? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.saddam.rigging/site_environment")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "connectivity" -> {
                        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                        val network = manager.activeNetwork
                        val caps = if (network == null) null else manager.getNetworkCapabilities(network)
                        result.success(when {
                            caps == null -> "OFFLINE"
                            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) -> "INTERNET VALIDATED"
                            else -> "NETWORK PRESENT - INTERNET UNVERIFIED"
                        })
                    }
                    "location" -> captureLocation(result)
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun captureLocation(result: MethodChannel.Result) {
        if (pendingResult != null) { result.error("BUSY", "Location request already running.", null); return }
        val fine = checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!fine && !coarse) { result.error("PERMISSION", "Location permission is optional. Use manual entry.", null); return }
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val provider = when {
            fine && manager.isProviderEnabled(LocationManager.GPS_PROVIDER) -> LocationManager.GPS_PROVIDER
            manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) -> LocationManager.NETWORK_PROVIDER
            else -> null
        }
        if (provider == null) { result.error("UNAVAILABLE", "Location is unavailable. Use manual entry.", null); return }
        pendingResult = result
        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                finishLocation(mapOf("latitude" to location.latitude, "longitude" to location.longitude,
                    "accuracyM" to if (location.hasAccuracy()) location.accuracy.toDouble() else null,
                    "observedAtEpochMs" to location.time, "provider" to location.provider), null)
            }
            override fun onProviderDisabled(provider: String) { finishLocation(null, "Location provider disabled. Use manual entry.") }
            override fun onProviderEnabled(provider: String) {}
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        }
        pendingLocation = listener
        val timeout = Runnable { finishLocation(null, "Location timed out. Use manual entry.") }
        pendingTimeout = timeout
        handler.postDelayed(timeout, 15000)
        try { manager.requestSingleUpdate(provider, listener, Looper.getMainLooper()) }
        catch (_: Exception) { finishLocation(null, "Location could not be obtained. Use manual entry.") }
    }

    private fun finishLocation(value: Map<String, Any?>?, error: String?) {
        val result = pendingResult ?: return
        pendingResult = null
        pendingTimeout?.let { handler.removeCallbacks(it) }; pendingTimeout = null
        pendingLocation?.let {
            try { (getSystemService(Context.LOCATION_SERVICE) as LocationManager).removeUpdates(it) } catch (_: Exception) {}
        }
        pendingLocation = null
        if (error == null) result.success(value) else result.error("UNAVAILABLE", error, null)
    }
    override fun onDestroy() {
        finishLocation(null, "Location capture stopped.")
        super.onDestroy()
    }
}
