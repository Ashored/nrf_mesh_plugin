import 'package:flutter/material.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

class SendGenericLevel extends StatefulWidget {
  final MeshManagerApi meshManagerApi;

  const SendGenericLevel({Key key, this.meshManagerApi}) : super(key: key);

  @override
  _SendGenericLevelState createState() => _SendGenericLevelState();
}

class _SendGenericLevelState extends State<SendGenericLevel> {
  int selectedElementAddress;

  int selectedLevel;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: ValueKey('module-send-generic-level-form'),
      title: Text('Send a generic level set'),
      children: <Widget>[
        TextField(
          key: ValueKey('module-send-generic-level-address'),
          decoration: InputDecoration(hintText: 'Element Address'),
          onChanged: (text) {
            selectedElementAddress = int.parse(text);
          },
        ),
        TextField(
          key: ValueKey('module-send-generic-level-value'),
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

            final provisionedNode = nodes.firstWhere((element) => element.uuid == provisionerUuid, orElse: () => null);
            final sequenceNumber = await widget.meshManagerApi.getSequenceNumber(provisionedNode);
            final status =
                await widget.meshManagerApi.sendGenericLevelSet(selectedElementAddress, selectedLevel, sequenceNumber);
            print(status);
          },
        )
      ],
    );
  }
}
