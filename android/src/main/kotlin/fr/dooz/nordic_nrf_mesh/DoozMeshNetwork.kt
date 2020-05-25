package fr.dooz.nordic_nrf_mesh

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import no.nordicsemi.android.mesh.MeshNetwork

class DoozMeshNetwork(private val binaryMessenger: BinaryMessenger, private val meshNetwork: MeshNetwork?) : EventChannel.StreamHandler, MethodChannel.MethodCallHandler {

    private  var eventSink : EventChannel.EventSink? = null

    init {
        EventChannel(binaryMessenger,"$namespace/mesh_manager_api/events").setStreamHandler(this)
        MethodChannel(binaryMessenger,"$namespace/mesh_manager_api/events").setMethodCallHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getId" -> {
                result.success(meshNetwork?.id)
            }
        }
    }
}