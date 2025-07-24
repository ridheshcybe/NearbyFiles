// MainActivity.kt
package com.ridheshcybe.nearbyfiles

import android.Manifest
import android.app.AlertDialog
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.nio.charset.StandardCharsets

class MainActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "NearbyFileTransfer"
        private const val SERVICE_ID = "com.example.nearbyfiletransfer"
        private const val REQUEST_CODE_REQUIRED_PERMISSIONS = 1

        // Required permissions for Nearby Connections (Legacy)
        private val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.BLUETOOTH,
            Manifest.permission.BLUETOOTH_ADMIN,
            Manifest.permission.ACCESS_WIFI_STATE,
            Manifest.permission.CHANGE_WIFI_STATE,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.READ_EXTERNAL_STORAGE
        )

        // Android 12+ permissions
        private val REQUIRED_PERMISSIONS_API_31 = arrayOf(
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.NEARBY_WIFI_DEVICES,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.READ_EXTERNAL_STORAGE
        )

        // Android 13+ permissions
        private val REQUIRED_PERMISSIONS_API_33 = arrayOf(
            Manifest.permission.BLUETOOTH_ADVERTISE,
            Manifest.permission.BLUETOOTH_CONNECT,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.NEARBY_WIFI_DEVICES,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.READ_MEDIA_IMAGES,
            Manifest.permission.READ_MEDIA_VIDEO,
            Manifest.permission.READ_MEDIA_AUDIO
        )
    }

    private lateinit var connectionsClient: ConnectionsClient
    private lateinit var localUserName: String
    private val connectedEndpoints = mutableListOf<String>()

    private lateinit var btnAdvertise: Button
    private lateinit var btnDiscover: Button
    private lateinit var btnSendFile: Button
    private lateinit var btnStopAll: Button
    private lateinit var tvStatus: TextView
    private lateinit var tvConnections: TextView

    private var isAdvertising = false
    private var isDiscovering = false

    // File picker launcher
    private val filePickerLauncher = registerForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let { sendFile(it) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)


        initViews()
        connectionsClient = Nearby.getConnectionsClient(this)
        localUserName = "User_${System.currentTimeMillis() % 10000}"

        if (!hasPermissions()) {
            requestPermissions()
        }

        setupClickListeners()
        updateUI()
    }

    private fun initViews() {
        btnAdvertise = findViewById(R.id.btnAdvertise)
        btnDiscover = findViewById(R.id.btnDiscover)
        btnSendFile = findViewById(R.id.btnSendFile)
        btnStopAll = findViewById(R.id.btnStopAll)
        tvStatus = findViewById(R.id.tvStatus)
        tvConnections = findViewById(R.id.tvConnections)
    }

    private fun setupClickListeners() {
        btnAdvertise.setOnClickListener {
            if (!isAdvertising) {
                startAdvertising()
            } else {
                stopAdvertising()
            }
        }

        btnDiscover.setOnClickListener {
            if (!isDiscovering) {
                startDiscovery()
            } else {
                stopDiscovery()
            }
        }

        btnSendFile.setOnClickListener {
            filePickerLauncher.launch("*/*")
        }

        btnStopAll.setOnClickListener {
            stopAll()
        }
    }

    private fun startAdvertising() {
        if (!hasPermissions()) {
            requestPermissions()
            return
        }

        val advertisingOptions = AdvertisingOptions.Builder()
            .setStrategy(Strategy.P2P_STAR)
            .build()

        connectionsClient
            .startAdvertising(localUserName, SERVICE_ID, connectionLifecycleCallback, advertisingOptions)
            .addOnSuccessListener {
                isAdvertising = true
                updateUI()
                tvStatus.text = "Advertising as: $localUserName"
                Log.d(TAG, "Started advertising")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to start advertising", e)
                tvStatus.text = "Failed to start advertising: ${e.message}"
            }
    }

    private fun stopAdvertising() {
        connectionsClient.stopAdvertising()
        isAdvertising = false
        updateUI()
        tvStatus.text = "Stopped advertising"
        Log.d(TAG, "Stopped advertising")
    }

    private fun startDiscovery() {
        if (!hasPermissions()) {
            requestPermissions()
            return
        }

        val discoveryOptions = DiscoveryOptions.Builder()
            .setStrategy(Strategy.P2P_STAR)
            .build()

        connectionsClient
            .startDiscovery(SERVICE_ID, endpointDiscoveryCallback, discoveryOptions)
            .addOnSuccessListener {
                isDiscovering = true
                updateUI()
                tvStatus.text = "Discovering devices..."
                Log.d(TAG, "Started discovery")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to start discovery", e)
                tvStatus.text = "Failed to start discovery: ${e.message}"
            }
    }

    private fun stopDiscovery() {
        connectionsClient.stopDiscovery()
        isDiscovering = false
        updateUI()
        tvStatus.text = "Stopped discovery"
        Log.d(TAG, "Stopped discovery")
    }

    private fun stopAll() {
        connectionsClient.stopAllEndpoints()
        connectionsClient.stopAdvertising()
        connectionsClient.stopDiscovery()

        isAdvertising = false
        isDiscovering = false
        connectedEndpoints.clear()

        updateUI()
        tvStatus.text = "Stopped all connections"
        Log.d(TAG, "Stopped all connections")
    }

    private fun updateUI() {
        btnAdvertise.text = if (isAdvertising) "Stop Advertising" else "Start Advertising"
        btnDiscover.text = if (isDiscovering) "Stop Discovery" else "Start Discovery"
        btnSendFile.isEnabled = connectedEndpoints.isNotEmpty()

        tvConnections.text = if (connectedEndpoints.isEmpty()) {
            "No connections"
        } else {
            "Connected to: ${connectedEndpoints.size} device(s)"
        }
    }

    // Connection Lifecycle Callback
    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
            Log.d(TAG, "Connection initiated with: ${connectionInfo.endpointName}")
            val builder: AlertDialog.Builder = AlertDialog.Builder(this@MainActivity)
            builder.setMessage("Do you want to proceed connecting with ${connectionInfo.endpointName}?")
                .setPositiveButton("Yes", { dialog, which ->
                    connectionsClient.acceptConnection(endpointId, payloadCallback)
                    Toast.makeText(this@MainActivity, "Connection Initalizing", Toast.LENGTH_SHORT).show()
                    "Connection initiated with: ${connectionInfo.endpointName}".also { tvStatus.text = it }
                })
                .setNegativeButton("No", { dialog, which ->
                    Toast.makeText(this@MainActivity, "Connection rejected", Toast.LENGTH_SHORT).show()
                })
                .show()
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            if (result.status.isSuccess) {
                Log.d(TAG, "Connected to: $endpointId")
                connectedEndpoints.add(endpointId)
                updateUI()
                Toast.makeText(this@MainActivity, "Connected successfully!", Toast.LENGTH_SHORT).show()
                tvStatus.text = "Connected successfully!"
            } else {
                Toast.makeText(this@MainActivity, "Connection failed! we're sorry try again", Toast.LENGTH_SHORT).show()
                Log.d(TAG, "Connection failed to: $endpointId")
                tvStatus.text = "Connection failed"
            }
        }

        override fun onDisconnected(endpointId: String) {
            Log.d(TAG, "Disconnected from: $endpointId")
            connectedEndpoints.remove(endpointId)
            updateUI()
            Toast.makeText(this@MainActivity, "Disconnected!", Toast.LENGTH_SHORT).show()
            tvStatus.text = "Device disconnected"
        }
    }

    // Endpoint Discovery Callback
    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            Log.d(TAG, "Endpoint found: ${info.endpointName}")
            connectionsClient.requestConnection(localUserName, endpointId, connectionLifecycleCallback)
            tvStatus.text = "Found device: ${info.endpointName}, connecting..."
        }

        override fun onEndpointLost(endpointId: String) {
            Log.d(TAG, "Endpoint lost: $endpointId")
            tvStatus.text = "Device lost"
        }
    }

    // Payload Callback
    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            if (payload.type == Payload.Type.BYTES) {
                val receivedBytes = payload.asBytes()
                val receivedText = String(receivedBytes!!, StandardCharsets.UTF_8)
                Log.d(TAG, "Received payload: $receivedText")
                runOnUiThread {
                    val preview = receivedText.take(50)
                    tvStatus.text = "Received: $preview..."
                    Toast.makeText(this@MainActivity, "File received!", Toast.LENGTH_SHORT).show()
                }
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            when (update.status) {
                PayloadTransferUpdate.Status.SUCCESS -> {
                    Log.d(TAG, "Payload transfer successful")
                    runOnUiThread {
                        Toast.makeText(this@MainActivity, "Transfer completed!", Toast.LENGTH_SHORT).show()
                    }
                }
                PayloadTransferUpdate.Status.FAILURE -> {
                    Log.e(TAG, "Payload transfer failed")
                    runOnUiThread {
                        Toast.makeText(this@MainActivity, "Transfer failed!", Toast.LENGTH_SHORT).show()
                    }
                }
                PayloadTransferUpdate.Status.IN_PROGRESS -> {
                    val transferred = update.bytesTransferred
                    val total = update.totalBytes
                    val progress = ((transferred * 100) / total).toInt()
                    Log.d(TAG, "Transfer progress: $progress%")
                    runOnUiThread {
                        tvStatus.text = "Transfer progress: $progress%"
                    }
                }
            }
        }
    }

    private fun sendFile(fileUri: Uri) {
        try {
            val inputStream = contentResolver.openInputStream(fileUri)
            val fileBytes = inputStream?.use { readBytesFromInputStream(it) }

            if (fileBytes != null) {
                val payload = Payload.fromBytes(fileBytes)

                connectedEndpoints.forEach { endpointId ->
                    connectionsClient.sendPayload(endpointId, payload)
                }

                tvStatus.text = "Sending file (${fileBytes.size} bytes)..."
                Toast.makeText(this, "Sending file to ${connectedEndpoints.size} device(s)", Toast.LENGTH_SHORT).show()
            }

        } catch (e: IOException) {
            Log.e(TAG, "Failed to read file", e)
            Toast.makeText(this, "Failed to read file", Toast.LENGTH_SHORT).show()
        }
    }

    @Throws(IOException::class)
    private fun readBytesFromInputStream(inputStream: java.io.InputStream): ByteArray {
        val buffer = ByteArrayOutputStream()
        val data = ByteArray(1024)
        var bytesRead: Int

        while (inputStream.read(data, 0, data.size).also { bytesRead = it } != -1) {
            buffer.write(data, 0, bytesRead)
        }

        return buffer.toByteArray()
    }

    private fun hasPermissions(): Boolean {
        val permissions = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> REQUIRED_PERMISSIONS_API_33
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> REQUIRED_PERMISSIONS_API_31
            else -> REQUIRED_PERMISSIONS
        }

        return permissions.all { permission ->
            ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        val permissions = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> REQUIRED_PERMISSIONS_API_33
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> REQUIRED_PERMISSIONS_API_31
            else -> REQUIRED_PERMISSIONS
        }
        ActivityCompat.requestPermissions(this, permissions, REQUEST_CODE_REQUIRED_PERMISSIONS)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == REQUEST_CODE_REQUIRED_PERMISSIONS) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }

            if (!allGranted) {
                Toast.makeText(this, "Permissions required for Nearby Connections", Toast.LENGTH_LONG).show()
                finish()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAll()
    }
}