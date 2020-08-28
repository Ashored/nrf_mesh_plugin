//
//  Constants.swift
//  nordic_nrf_mesh
//
//  Created by Alexis Barat on 01/06/2020.
//

import Foundation

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print(items[0], separator:separator, terminator: terminator)
    #endif
}

struct DoozStorage{
    static let fileName = "DoozMeshNetwork.json"
}

struct FlutterChannels{
    private static let prodNamespace = "fr.dooz.nordic_nrf_mesh"
    
    private static let namespace = prodNamespace
    
    private static let eventsUrl = "/events"
    private static let methodsUrl = "/methods"
    
    struct Plugin{
        static func getMethodChannelName() -> String{
            return "\(namespace)\(methodsUrl)"
        }
    }
    
    struct DoozMeshNetwork{
        static let url = "/mesh_network"
        
        static func getEventChannelName(networkId: String) -> String{
            return "\(namespace)\(url)/\(networkId)\(eventsUrl)"
        }
        
        static func getMethodChannelName(networkId: String) -> String{
            return "\(namespace)\(url)/\(networkId)\(methodsUrl)"
        }
        
    }
    
    struct MeshManagerApi{
        static let url = "/mesh_manager_api"
        
        static func getEventChannelName() -> String{
            return "\(namespace)\(url)\(eventsUrl)"
        }
        
        static func getMethodChannelName() -> String{
            return "\(namespace)\(url)\(methodsUrl)"
        }
    }
    
    struct DoozUnprovisionedMeshNode{
        static let url = "/unprovisioned_mesh_node"
        
        static func getMethodChannelName(deviceUUID: String) -> String{
            return "\(namespace)\(url)/\(deviceUUID)\(methodsUrl)"
        }
    }
    
    struct DoozProvisionedMeshNode{
        static let url = "/provisioned_mesh_node"
        
        static func getMethodChannelName(deviceUUID: String) -> String{
            return "\(namespace)\(url)/\(deviceUUID)\(methodsUrl)"
        }
    }
        
}

enum MeshNetworkApiEvent: String{
    case onNetworkLoaded
    case onNetworkImported
    case onNetworkUpdated
    
    case onNetworkLoadFailed
    case onNetworkImportFailed
}

enum ProvisioningEvent: String{
    case onProvisioningCompleted
    case onProvisioningFailed
    case onProvisioningStateChanged
    
    case onConfigAppKeyStatus
    case sendProvisioningPdu
}

enum MessageEvent: String{
    case onMeshPduCreated
    case onConfigModelAppStatus
}

enum EventSinkKeys: String{
    enum message: String{
        case elementAddress
        case modelId
        case appKeyIndex
    }
    
    enum network: String{
        case uuid
    }
    enum meshNode: String{
        case meshNode
        case uuid
        enum elements: String{
            case key
            case address
            case locationDescriptor
            case models
            enum model: String{
                case key
                case modelId
                case subscribedAddresses
                case boundAppKey
            }
        }
    }
    case eventName
    case id
    case error
    case state
    case pdu
    case data
}
//"key": element.index,
//                  "address" : element.unicastAddress,
//                  "locationDescriptor" : element.location.rawValue,
//                  "models" : element.models.enumerated().map({ (index,model) in
//                      return [
//                          "key" : index,
//                          "id" : model.modelIdentifier,
//                          "subscribedAddresses" : model.subscriptions.map{ sub in
//                              return sub.address
//                          }
//                      ]
//                  })
