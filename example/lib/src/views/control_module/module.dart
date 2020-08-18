import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import 'node.dart';

class Module extends StatefulWidget {
  final BluetoothDevice device;
  final MeshManagerApi meshManagerApi;

  const Module({Key key, this.device, this.meshManagerApi}) : super(key: key);

  @override
  _ModuleState createState() => _ModuleState();
}

class _ModuleState extends State<Module> {
  bool isLoading = true;
  int selectedElementAddress;
  int selectedLevel;
  ProvisionedMeshNode currentNode;
  final bleMeshManager = BleMeshManager();

  @override
  void initState() {
    super.initState();

    bleMeshManager.callbacks = DoozProvisionedBleMeshManagerCallbacks(widget.meshManagerApi, bleMeshManager);

    _init();
  }

  @override
  void dispose() async {
    super.dispose();
    await bleMeshManager.disconnect();
    await bleMeshManager.callbacks.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = Center(
      child: CircularProgressIndicator(),
    );
    if (!isLoading) {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Node(currentNode),
          Divider(),
          Text('Send a generic level set'),
          TextField(
            decoration: InputDecoration(hintText: 'Element Address'),
            onChanged: (text) {
              selectedElementAddress = int.parse(text);
            },
          ),
          TextField(
            decoration: InputDecoration(hintText: 'Level Value'),
            onChanged: (text) {
              selectedLevel = int.parse(text);
            },
          ),
          RaisedButton(
            child: Text('Send level'),
            onPressed: () async {
              print('send level $selectedLevel to $selectedElementAddress');
              final provisionerUuid = await widget.meshManagerApi.meshNetwork.selectedProvisionerUuid();
              final nodes = await widget.meshManagerApi.meshNetwork.nodes;

              final provisionedNode =
                  nodes.firstWhere((element) => element.uuid == provisionerUuid, orElse: () => null);
              final provisionerAddress = await provisionedNode.unicastAddress;
              final sequenceNumber = await widget.meshManagerApi.meshNetwork.getSequenceNumber(provisionerAddress);
              final status = await widget.meshManagerApi
                  .sendGenericLevelSet(selectedElementAddress, selectedLevel, sequenceNumber);
              print(status);
            },
          )
        ],
      );
    }
    return Scaffold(
      body: body,
    );
  }

  Future<void> _init() async {
    await bleMeshManager.connect(widget.device);
    final _nodes = await widget.meshManagerApi.meshNetwork.nodes;

    final provisionerUuid = await widget.meshManagerApi.meshNetwork.selectedProvisionerUuid();
    final provisioner = _nodes.firstWhere((element) => element.uuid == provisionerUuid, orElse: () => null);
    if (provisioner == null) {
      print('provisioner is null');
      return;
    }

    currentNode = await currentConnectedMeshNode(widget.device.id.id, _nodes);
    if (currentNode == null) {
      print('node mesh node connected');
      return;
    }
    for (final element in await currentNode.elements) {
      for (final model in element.models) {
        if (model.boundAppKey.isEmpty) {
          final unicast = await currentNode.unicastAddress;
          print('need to bind app key');
          await widget.meshManagerApi.sendConfigModelAppBind(
            unicast,
            element.address,
            model.modelId,
          );
        }
      }
    }

    //  check if the board need to be configured
    final data = BoardData(0, 0x1f, 0);
    print('send generic level set to ${await currentNode.unicastAddress} level ${data.toByte()}');
    final getBoardTypeStatus = await widget.meshManagerApi
        .sendGenericLevelSet(await currentNode.unicastAddress, data.toByte(), await provisioner.sequenceNumber);
    print(getBoardTypeStatus);
    final boardType = BoardData.decode(getBoardTypeStatus.level);
    if (boardType.payload == 0xA) {
      print('Doobl V');
      print('setup sortie 1 to be a dimmer');
      final data = BoardData(0, 0x1, 0x1);
      final setupDimmerStatus = await widget.meshManagerApi
          .sendGenericLevelSet(await currentNode.unicastAddress, data.toByte(), await provisioner.sequenceNumber);
      final dimmerBoardData = BoardData.decode(setupDimmerStatus.level);
      print(dimmerBoardData);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<ProvisionedMeshNode> currentConnectedMeshNode(String macAddress, List<ProvisionedMeshNode> nodes) async {
    for (final node in nodes) {
      final name = await node.name;
      if (name == macAddress) {
        return node;
      }
    }
    return null;
  }
}

class BoardData {
  final int targetIo;
  final int offset;
  final int payload;

  BoardData(this.targetIo, this.offset, this.payload);

  factory BoardData.decode(int level) {
    final payload = (level & 0x1FF).toString();
    final offset = ((level >> 9) & 0x1F).toString();
    var io = (level >> (9 + 5)) & 0x3;
    if (level < 0) {
      io = io | 0x02;
    }
    return BoardData(io, int.tryParse(offset), int.tryParse(payload));
  }

  int toByte() {
    int buff;
    int outLevel;
    buff = ((targetIo & 0x3) << (9 + 5)) | ((offset & 0x1f) << (9)) | (payload & 0x1FF);
    buff = buff.toUnsigned(16);
    if (buff & (1 << 15) != 0) {
      buff = ~buff ^ 0x01;
      outLevel = buff * -1;
    } else {
      outLevel = buff;
    }
    return outLevel;
  }

  @override
  String toString() => 'targetIo: $targetIo, offset: $offset, payload: $payload';
}

class DoozProvisionedBleMeshManagerCallbacks extends BleMeshManagerCallbacks {
  final MeshManagerApi meshManagerApi;
  final BleMeshManager bleMeshManager;

  StreamSubscription<BluetoothDevice> onDeviceConnectingSubscription;
  StreamSubscription<BluetoothDevice> onDeviceConnectedSubscription;
  StreamSubscription<BleManagerCallbacksDiscoveredServices> onServicesDiscoveredSubscription;
  StreamSubscription<BluetoothDevice> onDeviceReadySubscription;
  StreamSubscription<BleMeshManagerCallbacksDataReceived> onDataReceivedSubscription;
  StreamSubscription<BleMeshManagerCallbacksDataSent> onDataSentSubscription;
  StreamSubscription<BluetoothDevice> onDeviceDisconnectingSubscription;
  StreamSubscription<BluetoothDevice> onDeviceDisconnectedSubscription;
  StreamSubscription<List<int>> onMeshPduCreatedSubscription;

  DoozProvisionedBleMeshManagerCallbacks(this.meshManagerApi, this.bleMeshManager) {
    onDeviceConnectingSubscription = onDeviceConnecting.listen((event) {
      print('onDeviceConnecting $event');
    });
    onDeviceConnectedSubscription = onDeviceConnected.listen((event) {
      print('onDeviceConnected $event');
    });

    onServicesDiscoveredSubscription = onServicesDiscovered.listen((event) {
      print('onServicesDiscovered');
    });

    onDeviceReadySubscription = onDeviceReady.listen((event) async {
      print('onDeviceReady ${event.id.id}');
    });

    onDataReceivedSubscription = onDataReceived.listen((event) async {
      print('onDataReceived ${event.device.id} ${event.pdu} ${event.mtu}');
      await meshManagerApi.handleNotifications(event.mtu, event.pdu);
    });
    onDataSentSubscription = onDataSent.listen((event) async {
      print('onDataSent ${event.device.id} ${event.pdu} ${event.mtu}');
      await meshManagerApi.handleWriteCallbacks(event.mtu, event.pdu);
    });

    onDeviceDisconnectingSubscription = onDeviceDisconnecting.listen((event) {
      print('onDeviceDisconnecting $event');
    });
    onDeviceDisconnectedSubscription = onDeviceDisconnected.listen((event) {
      print('onDeviceDisconnected $event');
    });

    onMeshPduCreatedSubscription = meshManagerApi.onMeshPduCreated.listen((event) async {
      print('onMeshPduCreated $event');
      await bleMeshManager.sendPdu(event);
    });
  }

  @override
  Future<void> dispose() => Future.wait([
        onDeviceConnectingSubscription.cancel(),
        onDeviceConnectedSubscription.cancel(),
        onServicesDiscoveredSubscription.cancel(),
        onDeviceReadySubscription.cancel(),
        onDataReceivedSubscription.cancel(),
        onDataSentSubscription.cancel(),
        onDeviceDisconnectingSubscription.cancel(),
        onDeviceDisconnectedSubscription.cancel(),
        onMeshPduCreatedSubscription.cancel(),
        super.dispose(),
      ]);

  @override
  Future<void> sendMtuToMeshManagerApi(int mtu) => meshManagerApi.setMtu(mtu);
}
