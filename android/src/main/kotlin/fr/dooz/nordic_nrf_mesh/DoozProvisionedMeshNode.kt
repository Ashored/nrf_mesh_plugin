package fr.dooz.nordic_nrf_mesh

import android.annotation.SuppressLint
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import no.nordicsemi.android.mesh.transport.ProvisionedMeshNode

class DoozProvisionedMeshNode(binaryMessenger: BinaryMessenger, var meshNode: ProvisionedMeshNode): MethodChannel.MethodCallHandler {
    init {
        MethodChannel(binaryMessenger, "$namespace/provisioned_mesh_node/${meshNode.uuid}/methods").setMethodCallHandler(this)
    }

    @SuppressLint("RestrictedApi")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "nodeName" -> {
                val nodeName = call.argument<String>("name")!!
                meshNode.nodeName = nodeName
                result.success(null)
            }
            "elementAt" -> {

            }
            "elements" -> {
                result.success(meshNode.elements.map { element ->
                    mapOf(
                            "key" to element.key,
                            "address" to element.value.elementAddress,
                            "location" to element.value.locationDescriptor,
                            "models" to element.value.meshModels.map {
                                mapOf(
                                        "key" to it.key,
                                        "id" to it.value.modelId,
                                        "subscribedAddresses" to it.value.subscribedAddresses,
                                        "pub" to it.value.publicationSettings
                                )
                            }
                    )
                })
            }
            "unicastAddress" -> {
                result.success(meshNode.unicastAddress)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}