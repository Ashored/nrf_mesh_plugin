//
//  DoozMeshManagerApi.swift
//  nordic_nrf_mesh
//
//  Created by Alexis Barat on 29/05/2020.
//

import Foundation
import nRFMeshProvision

class DoozMeshManagerApi: NSObject{
    
    //MARK: Public properties
    var meshNetworkManager: MeshNetworkManager?
    var delegate: DoozMeshManagerApiDelegate?
    
    var mtuSize: Int = -1
    
    //MARK: Private properties
    private var doozMeshNetwork: DoozMeshNetwork?
    private var eventSink: FlutterEventSink?
    private var messenger: FlutterBinaryMessenger?
    private var doozStorage: LocalStorage?
    
    private var doozProvisioningManager: DoozProvisioningManager?
    private var doozTransmitter: DoozTransmitter?
    
    init(messenger: FlutterBinaryMessenger) {
        super.init()
        
        self.messenger = messenger
        self.delegate = self
        
        _initMeshNetworkManager()
        _initChannels(messenger: messenger)
        _initDoozProvisioningManager()
    }
    
}


private extension DoozMeshManagerApi {
    
    func _initMeshNetworkManager(){
        
        self.doozStorage = LocalStorage(fileName: DoozStorage.fileName)
        guard let _doozStorage = self.doozStorage else{
            return
        }
        
        meshNetworkManager = MeshNetworkManager(using: _doozStorage)
        meshNetworkManager?.logger = self
        
        guard let _meshNetworkManager = self.meshNetworkManager else{
            return
        }
        
        _meshNetworkManager.acknowledgmentTimerInterval = 0.150
        _meshNetworkManager.transmissionTimerInteral = 0.600
        _meshNetworkManager.incompleteMessageTimeout = 10.0
        _meshNetworkManager.retransmissionLimit = 2
        _meshNetworkManager.acknowledgmentMessageInterval = 4.2
        
        // As the interval has been increased, the timeout can be adjusted.
        // The acknowledged message will be repeated after 4.2 seconds,
        // 12.6 seconds (4.2 + 4.2 * 2), and 29.4 seconds (4.2 + 4.2 * 2 + 4.2 * 4).
        // Then, leave 10 seconds for until the incomplete message times out.
        _meshNetworkManager.acknowledgmentMessageTimeout = 40.0
        
    }
    
    func _initChannels(messenger: FlutterBinaryMessenger){
        
        FlutterEventChannel(
            name: FlutterChannels.MeshManagerApi.getEventChannelName(),
            binaryMessenger: messenger
        )
            .setStreamHandler(self)
        
        FlutterMethodChannel(
            name: FlutterChannels.MeshManagerApi.getMethodChannelName(),
            binaryMessenger: messenger
        )
            .setMethodCallHandler({ (call, result) in
                self._handleMethodCall(call, result: result)
            })
        
    }
    
    func _initDoozProvisioningManager(){
        guard let _meshNetworkManager = self.meshNetworkManager, let _messenger = self.messenger else{
            return
        }
        
        doozProvisioningManager = DoozProvisioningManager(meshNetworkManager: _meshNetworkManager, messenger: _messenger, delegate: self)
    }
    
    func _handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🥂 [DoozMeshManagerApi] Received flutter call : \(call.method)")
        guard let _method = DoozMeshManagerApiChannel(rawValue: call.method) else{
            print("❌ Plugin method - \(call.method) - isn't implemented")
            return
        }
        
        switch _method {
            
        case .loadMeshNetwork:
            _loadMeshNetwork()
            result(nil)
            break
        case .importMeshNetworkJson:
            if let _args = call.arguments as? [String:Any], let _json = _args["json"] as? String{
                _importMeshNetworkJson(_json)
            }
            result(nil)
            break
        case .deleteMeshNetworkFromDb:
            if let _args = call.arguments as? [String:Any], let _id = _args["id"] as? String{
                
                do{
                    try _deleteMeshNetworkFromDb(_id)
                }catch{
                    #warning("TODO: Manage errors on delete")
                }
                
            }
            break
        case .exportMeshNetwork:
            if let json = _exportMeshNetwork(){
                result(json)
            }
            break
        case .identifyNode:
            
            if
                let _doozProvisioningManager = self.doozProvisioningManager,
                let _args = call.arguments as? [String:Any],
                let _strServiceUUID = _args["serviceUuid"] as? String,
                let _serviceUUID = UUID(uuidString: _strServiceUUID)
            {
                _doozProvisioningManager.identifyNode(_serviceUUID)
            }
            
            result(nil)
            
            break
            
        case .provisioning:
            if let _doozProvisioningManager = self.doozProvisioningManager{
                _doozProvisioningManager.provision()
            }
            
            
            result(nil)
            
            break
            
        case .handleNotifications:
            if
                let _args = call.arguments as? [String:Any],
                let _pdu = _args["pdu"] as? FlutterStandardTypedData
            {
                self._didDeliverData(data: _pdu.data)
                
            }
            
            result(nil)
            
            break
            
        case .setMtuSize:
            
            if let _args = call.arguments as? [String:Any], let _mtuSize = _args["mtuSize"] as? Int{
                delegate?.mtuSize = _mtuSize
                result(nil)
            }
            break
        case .cleanProvisioningData:
            if
                let _doozProvisioningManager = self.doozProvisioningManager{
                _doozProvisioningManager.cleanProvisioningData()
            }
            result(nil)
            
        case .createMeshPduForConfigCompositionDataGet:
            doozProvisioningManager?.createMeshPduForConfigCompositionDataGet()
            result(nil)
            
        case .sendGenericLevelSet:
            if
                let _args = call.arguments as? [String:Any],
                let _address = _args["address"] as? Int16,
                let _level = _args["level"] as? Int16,
                let _meshNetworkManager = self.meshNetworkManager,
                let _appKey = _meshNetworkManager.meshNetwork?.applicationKeys.first{
                
                let message = GenericLevelSet(level: _level)
                
                self.doozTransmitter = DoozTransmitter()
                _meshNetworkManager.transmitter = doozTransmitter
                
                do{
                    _ = try _meshNetworkManager.send(
                        message,
                        to: MeshAddress(Address(bitPattern: _address)),
                        using: _appKey
                    )
                }catch{
                    #warning("TODO : manage errors")
                    print(error)
                }
                
            }
            
            result(nil)
        case .sendGenericOnOffSet:
            if
                let _args = call.arguments as? [String:Any],
                let _address = _args["address"] as? Int16,
                let _isOn = _args["value"] as? Bool,
                let _meshNetworkManager = self.meshNetworkManager,
                let _appKey = _meshNetworkManager.meshNetwork?.applicationKeys.first{
                
                let message = GenericOnOffSet(_isOn)
                
                self.doozTransmitter = DoozTransmitter()
                _meshNetworkManager.transmitter = doozTransmitter
                
                do{
                    _ = try _meshNetworkManager.send(
                        message,
                        to: MeshAddress(Address(bitPattern: _address)),
                        using: _appKey
                    )
                }catch{
                    #warning("TODO : manage errors")
                    print(error)
                }
                
            }
            
            result(nil)
            break
            

            
        case .sendConfigModelAppBind:
            if
                let _args = call.arguments as? [String:Any],
                let nodeId = _args["nodeId"] as? Int16, // nodeId is an unicastAddress
                let elementId = _args["elementId"] as? Int16, // elementId is an unicastAddress
                let modelId = _args["modelId"] as? UInt32,
                let appKeyIndex = _args["appKeyIndex"] as? Int16,
                let _meshNetworkManager = self.meshNetworkManager{
                
//                var _modelId = modelId
                var _elementAddress = Address(bitPattern: elementId)
//                var _appKeyIndex = KeyIndex(bitPattern: appKeyIndex)
                
//                let data =
//                    Data()
//                    + Data(bytes: &_elementAddress, count: MemoryLayout<UInt16>.size)
//                    + Data(bytes: &_appKeyIndex, count: MemoryLayout<UInt16>.size)
//                    + Data(bytes: &_modelId, count: MemoryLayout<UInt16>.size)
                
                self.doozTransmitter = DoozTransmitter()
                doozTransmitter?.doozDelegate = self
                _meshNetworkManager.transmitter = doozTransmitter
                _meshNetworkManager.delegate = self
                _meshNetworkManager.localElements = []
                
                do{
                    let node = meshNetworkManager?.meshNetwork?.node(withAddress: Address(bitPattern: nodeId))
                    let element = node?.element(withAddress: Address(bitPattern: elementId))
                    let model = element?.model(withModelId: modelId)
                    let appKey = meshNetworkManager?.meshNetwork?.applicationKeys[KeyIndex(appKeyIndex)]
                    
                    if let _appKey = appKey, let _model = model{
                        
                        if let configModelAppBind = ConfigModelAppBind(applicationKey: _appKey, to: _model){
                            try _ =  _meshNetworkManager.send(configModelAppBind, to: _model)
//                            try _ = _meshNetworkManager.send(configModelAppBind, to: _elementAddress)
                        }
                    }
                    
                    
//                    if let configModelAppBind = ConfigModelAppBind(parameters: data){
//
//                    }
                }
                catch{
                    print(error)
                }
                
                
            }
            
            result(nil)
            //            val nodeId = call.argument<Int>("nodeId")!!
            //                           val elementId = call.argument<Int>("elementId")!!
            //                           val modelId = call.argument<Int>("modelId")!!
            //                           val appKeyIndex = call.argument<Int>("appKeyIndex")!!
            //                           val configModelAppBind = ConfigModelAppBind(elementId, modelId, appKeyIndex)
            //                           mMeshManagerApi.createMeshPdu(nodeId, configModelAppBind)
            //                           result.success(null)
            
        case .getSequenceNumberForAddress:
            if
                let _meshNetworkManager = self.meshNetworkManager,
                let _meshNetwork = _meshNetworkManager.meshNetwork,
                let _args = call.arguments as? [String:Any],
                let _nodeAddress = _args["address"] as? Int16,
                let _node = _meshNetwork.node(withAddress: Address(bitPattern: _nodeAddress)),
                _node.elementsCount > 0{
                
                let sequenceNumber = _meshNetworkManager.getSequenceNumber(ofLocalElement: _node.elements[0])
                result(sequenceNumber)
                
            }
            result(nil)
        }
        
    }
    
}


private extension DoozMeshManagerApi{
    // Events native implementations
//    #warning("remove")
//    func bindAppKey(to model: Model){
//          if let _meshNetworkManager = self.meshNetworkManager{
//              do{
//                  print("📩 Sending message : ConfigModelAppBind")
//
//                  if let _appKey = _meshNetworkManager.meshNetwork?.applicationKeys.first{
//
//                      guard let message = ConfigModelAppBind(applicationKey: _appKey, to: model) else {
//                          return
//                      }
//
//
//                      _ = try _meshNetworkManager.send(message, to: model)
//
//                      print("💪 BIND APP KEY TO MODEL \(model)")
//                  }
//              }catch{
//                  print(error)
//              }
//
//          }
//      }
    
    func _loadMeshNetwork(){
        guard let _meshNetworkManager = self.meshNetworkManager else{
            return
        }
        
        do{
            
            if try _meshNetworkManager.load(){
                // Mesh Network loaded from database
            }else{
                // No mesh network in database, we have to create one
                print("✅ No Mesh Network in database, creating a new one...")
                
                let meshNetwork = try _generateMeshNetwork()
                try _ = meshNetwork.add(applicationKey: Data.random128BitKey(), name: "AppKey")
                
                
                print("✅ Mesh Network successfully generated with name : \(meshNetwork.meshName)")
                
            }
            
            delegate?.onNetworkLoaded(_meshNetworkManager.meshNetwork)
            
        }catch{
            delegate?.onNetworkLoadFailed(error)
        }
        
    }
    
    
    func _importMeshNetworkJson(_ json: String){
        
        guard let _messenger = self.messenger, let _meshNetworkManager = self.meshNetworkManager else{
            return
        }
        
        do{
            if let data = json.data(using: .utf8){
                let _network = try _meshNetworkManager.import(from: data)
                
                print("✅ Json imported")
                
                if (doozMeshNetwork == nil || doozMeshNetwork?.meshNetwork?.id != _network.id) {
                    doozMeshNetwork = DoozMeshNetwork(messenger: _messenger, network: _network)
                } else {
                    doozMeshNetwork?.meshNetwork = _network
                }
                
                if let _eventSink = self.eventSink{
                    _eventSink(
                        [
                            EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkImported.rawValue,
                            EventSinkKeys.id.rawValue : _network.id
                    ])
                }
                #warning("save in db after import successful")
                //    delegate.onNetworkImported()
            }
            
        }catch{
            print("❌ Error importing json : \(error.localizedDescription)")
            // delegate.onNetworkImportFailed()
        }
    }
    
    func _deleteMeshNetworkFromDb(_ id: String) throws{
        
        // We have to implement the reset / delete logic on plugin side.
        // See https://github.com/NordicSemiconductor/IOS-nRF-Mesh-Library/issues/279
        
        guard let _doozStorage = self.doozStorage else{
            throw DoozMeshManagerApiError.doozStorageNotFound
        }
        
        do{
            try _doozStorage.delete()
        }catch{
            throw error
        }
        
    }
    
    func _exportMeshNetwork() -> String?{
        
        guard let _meshNetworkManager = self.meshNetworkManager else{
            return nil
        }
        
        let data = _meshNetworkManager.export()
        let str = String(decoding: data, as: UTF8.self)
        
        if str != ""{
            return str
        }
        
        return nil
        
    }
    
    func _generateMeshNetwork() throws -> MeshNetwork{
        
        guard let _meshNetworkManager = self.meshNetworkManager else{
            throw DoozMeshManagerApiError.meshManagerApiNotInitialized
        }
        
        let meshUUID = UUID().uuidString
        let provisioner = Provisioner(name: UIDevice.current.name,
                                      allocatedUnicastRange: [AddressRange(0x0001...0x199A)],
                                      allocatedGroupRange:   [AddressRange(0xC000...0xCC9A)],
                                      allocatedSceneRange:   [SceneRange(0x0001...0x3333)])
        
        let meshNetwork = _meshNetworkManager.createNewMeshNetwork(withName: meshUUID, by: provisioner)
        _ = _meshNetworkManager.save()
        
        return meshNetwork
    }
    
    func _resetMeshNetwork(){
        guard let _meshNetwork = self.meshNetworkManager?.meshNetwork else{
            return
        }
        
        // Delete the existing network in local database and recreate a new / empty Mesh Network
        do{
            try _deleteMeshNetworkFromDb(_meshNetwork.id)
            let meshNetwork = try _generateMeshNetwork()
            
            print("✅ Mesh Network successfully generated with name : \(meshNetwork.meshName)")
            
        }catch{
            print("❌ Error creating Mesh Network : \(error.localizedDescription)")
        }
        
    }
    
    func _didDeliverData(data: Data){
        
        guard
            let type = PduType(rawValue: UInt8(data[0])) else{
                return
        }
        
        let packet = data.subdata(in: 1 ..< data.count)
        
        switch type {
        case .provisioningPdu:
            guard let _doozProvisioningManager = self.doozProvisioningManager else{
                return
            }
            
            _doozProvisioningManager.didDeliverData(data, ofType: type)
            
        default:
            guard let _meshNetworkManager = self.meshNetworkManager else{
                return
            }
                        
            _meshNetworkManager.bearerDidDeliverData(packet, ofType: type)
        }
        
    }
}

extension DoozMeshManagerApi: FlutterStreamHandler{
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
}

extension DoozMeshManagerApi: DoozMeshManagerApiDelegate{
    
    
    func onNetworkLoaded(_ network: MeshNetwork?) {
        print("✅ Mesh Network loaded from database")
        
        guard
            let _network = network,
            let _messenger = self.messenger,
            let _eventSink = self.eventSink
            else{
                return
        }
        
        if (doozMeshNetwork == nil || doozMeshNetwork?.meshNetwork?.id != _network.id) {
            doozMeshNetwork = DoozMeshNetwork(messenger: _messenger, network: _network)
        } else {
            doozMeshNetwork?.meshNetwork = _network
        }
        
        _eventSink(
            [
                EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkLoaded.rawValue,
                EventSinkKeys.id.rawValue : _network.id
            ]
        )
        
    }
    
    func onNetworkLoadFailed(_ error: Error) {
        print("❌ Error loading Mesh Network : \(error.localizedDescription)")
        
        guard let _eventSink = self.eventSink else{
            return
        }
        
        _eventSink(
            [
                EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkLoadFailed.rawValue,
                EventSinkKeys.error.rawValue : error
            ]
        )
        
    }
    
    func onNetworkUpdated(_ network: MeshNetwork?) {
        
        print("✅ Mesh Network updated")
        
        guard
            let _network = network,
            let _eventSink = self.eventSink
            else{
                return
        }
        
        doozMeshNetwork?.meshNetwork = _network
        
        _eventSink(
            [
                EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkUpdated.rawValue,
                EventSinkKeys.id.rawValue : _network.id
            ]
        )
    }
    
    func onNetworkImported(_ network: MeshNetwork?) {
        
        print("✅ Mesh Network imported")
        
        guard
            let _network = network,
            let _messenger = self.messenger,
            let _eventSink = self.eventSink
            else{
                return
        }
        
        if (doozMeshNetwork == nil || doozMeshNetwork?.meshNetwork?.id != _network.id) {
            doozMeshNetwork = DoozMeshNetwork(messenger: _messenger, network: _network)
        } else {
            doozMeshNetwork?.meshNetwork = _network
        }
        
        _eventSink(
            [
                EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkImported.rawValue,
                EventSinkKeys.id.rawValue : _network.id
            ]
        )
        
    }
    
    func onNetworkImportFailed(_ error: Error) {
        print("❌ Error importing Mesh Network : \(error.localizedDescription)")
        
        guard let _eventSink = self.eventSink else{
            return
        }
        
        _eventSink(
            [
                EventSinkKeys.eventName.rawValue : MeshNetworkApiEvent.onNetworkImportFailed.rawValue,
                EventSinkKeys.error.rawValue : error
            ]
        )
    }
    
    
}

extension DoozMeshManagerApi: LoggerDelegate{
    func log(message: String, ofCategory category: LogCategory, withLevel level: LogLevel) {
        print("[\(String(describing: self.classForCoder))] \(message)")
    }
}

extension DoozMeshManagerApi: DoozProvisioningManagerDelegate{
    func provisioningStateDidChange(device: UnprovisionedDevice, state: ProvisionigState, eventSinkMessage: Dictionary<String, Any>){
        if let _eventSink = self.eventSink{
            _eventSink(eventSinkMessage)
        }
    }
    
    func sendMessage(_ msg: Dictionary<String, Any>) {
        if let _eventSink = self.eventSink{
            _eventSink(msg)
        }
    }
    
    func didFinishProvisioning() {
        if let _eventSink = self.eventSink{
            _eventSink(
                [
                    EventSinkKeys.eventName.rawValue : ProvisioningEvent.onConfigAppKeyStatus.rawValue
            ])
        }
    }
    
}


extension DoozMeshManagerApi: MeshNetworkDelegate{
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didReceiveMessage message: MeshMessage, sentFrom source: Address, to destination: Address) {
        print("📣 didReceiveMessage : \(message) from \(source) to \(destination)")

        
        // Handle the message based on its type.
        switch message {
            
        case let status as ConfigModelAppStatus:

            if status.isSuccess {
                let dict = [

                    EventSinkKeys.eventName.rawValue: MessageEvent.onConfigModelAppStatus.rawValue,
                    EventSinkKeys.message.elementAddress.rawValue: status.elementAddress,
                    EventSinkKeys.message.modelId.rawValue: status.modelId,
                    EventSinkKeys.message.appKeyIndex.rawValue: status.applicationKeyIndex,

                    ] as [String : Any]

                sendMessage(dict)
            } else {
                break
            }
            
        case let status as ConfigModelPublicationStatus:
            // If the Model is being refreshed, the Bindings, Subscriptions
            // and Publication has been read. If the Model has custom UI,
            // try refreshing it as well.
            break
            
        case let status as ConfigModelSubscriptionStatus:
            break
            
        case let list as ConfigModelAppList:
           break
        
            
        case let list as ConfigModelSubscriptionList:
            break
            
        default:
            break
        }
        
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, didSendMessage message: MeshMessage, from localElement: Element, to destination: Address) {
        print("📣 didSendMessage : \(message) from \(localElement) to \(destination)")
    }
    
    func meshNetworkManager(_ manager: MeshNetworkManager, failedToSendMessage message: MeshMessage, from localElement: Element, to destination: Address, error: Error) {
        print("📣 failedToSendMessage : \(message) from \(localElement) to \(destination) : \(error)")
    }
    
}

extension DoozMeshManagerApi: DoozPBGattBearerDelegate, DoozGattBearerDelegate, DoozTransmitterDelegate{
    func send(data: Data) {

        let dict = [
            
            EventSinkKeys.eventName.rawValue: MessageEvent.onMeshPduCreated.rawValue,
            EventSinkKeys.pdu.rawValue: data
            ] as [String : Any]
        
        sendMessage(dict)
        
    }
}
