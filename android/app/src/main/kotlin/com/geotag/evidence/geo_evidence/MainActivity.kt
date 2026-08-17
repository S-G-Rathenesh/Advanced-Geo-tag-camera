package com.geotag.evidence.geo_evidence

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.GnssStatus
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var gnssCallback: GnssStatus.Callback? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val mainHandler = Handler(Looper.getMainLooper())

        // Security Window Flags
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

        // Hardware Proximity Sensor EventChannel for Instant Finger / Camera Cover Detection
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.geotag.evidence/proximity").setStreamHandler(
            object : EventChannel.StreamHandler {
                private var sensorEventListener: SensorEventListener? = null
                private var sensorManager: SensorManager? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val sm = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
                    sensorManager = sm
                    val proximitySensor = sm?.getDefaultSensor(Sensor.TYPE_PROXIMITY)
                    if (proximitySensor == null) {
                        Log.w("ProximitySensor", "No proximity sensor found on device")
                        mainHandler.post { events?.success(false) }
                        return
                    }

                    sensorEventListener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent?) {
                            if (event != null && event.values.isNotEmpty()) {
                                val distance = event.values[0]
                                val maxRange = proximitySensor.maximumRange
                                // Near: distance is 0 or strictly less than maxRange or less than 5cm
                                val isNear = (distance < maxRange && distance < 5.0f) || distance == 0.0f
                                Log.d("ProximitySensor", "distance: $distance, maxRange: $maxRange -> isNear: $isNear")
                                mainHandler.post {
                                    events?.success(isNear)
                                }
                            }
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
                    }

                    sm.registerListener(
                        sensorEventListener,
                        proximitySensor,
                        SensorManager.SENSOR_DELAY_UI
                    )
                }

                override fun onCancel(arguments: Any?) {
                    sensorEventListener?.let { listener ->
                        sensorManager?.unregisterListener(listener)
                    }
                    sensorEventListener = null
                    sensorManager = null
                }
            }
        )

        // GNSS Satellite Constellation Tracker
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
                                    mainHandler.post {
                                        events?.success(usedConstellations.toList())
                                    }
                                }
                            }
                            locationManager.registerGnssStatusCallback(gnssCallback!!, mainHandler)
                        } else {
                            mainHandler.post {
                                events?.error("PERMISSION_DENIED", "Location permission is required for GNSS status", null)
                            }
                        }
                    } else {
                        mainHandler.post {
                            events?.error("UNSUPPORTED", "GNSS Status requires Android N (API 24) or higher", null)
                        }
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
