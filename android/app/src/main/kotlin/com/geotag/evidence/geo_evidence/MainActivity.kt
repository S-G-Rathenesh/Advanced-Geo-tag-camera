package com.geotag.evidence.geo_evidence

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.GnssStatus
import android.location.LocationManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager

class MainActivity: FlutterActivity() {
    private var gnssCallback: GnssStatus.Callback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.geotag.evidence/security").setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureMode" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "disableSecureMode" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.geotag.evidence/gnss").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                        if (ContextCompat.checkSelfPermission(this@MainActivity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                            gnssCallback = object : GnssStatus.Callback() {
                                override fun onSatelliteStatusChanged(status: GnssStatus) {
                                    val usedConstellations = mutableSetOf<String>()
                                    for (i in 0 until status.satelliteCount) {
                                        if (status.usedInFix(i)) {
                                            when (status.getConstellationType(i)) {
                                                GnssStatus.CONSTELLATION_GPS -> usedConstellations.add("GPS")
                                                GnssStatus.CONSTELLATION_GLONASS -> usedConstellations.add("GLONASS")
                                                GnssStatus.CONSTELLATION_GALILEO -> usedConstellations.add("Galileo")
                                                GnssStatus.CONSTELLATION_BEIDOU -> usedConstellations.add("BeiDou")
                                            }
                                        }
                                    }
                                    events?.success(usedConstellations.toList())
                                }
                            }
                            locationManager.registerGnssStatusCallback(gnssCallback!!, null)
                        } else {
                            events?.error("PERMISSION_DENIED", "Location permission is required for GNSS status", null)
                        }
                    } else {
                        events?.error("UNSUPPORTED", "GNSS Status requires Android N (API 24) or higher", null)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    if (gnssCallback != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                        locationManager.unregisterGnssStatusCallback(gnssCallback!!)
                        gnssCallback = null
                    }
                }
            }
        )
    }
}
