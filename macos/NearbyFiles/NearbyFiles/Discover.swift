//
//  Discover.swift
//  NearbyFiles
//
//  Created by ridhesh on 24/07/25.
//

import Foundation
import NearbyConnections

class Discover: ConnectionManagerDelegate {
  let connectionManager: ConnectionManager
  let discoverer: Discoverer
  
  /// A local collection to keep track of discovered endpoints and their context strings.
  private var discoveredEndpoints: [EndpointID: String] = [:]

  init() {
    connectionManager = ConnectionManager(serviceID: "com.example.app", strategy: .cluster)

    discoverer = Discoverer(connectionManager: connectionManager)
      connectionManager.delegate = self
    discoverer.delegate = self

    discoverer.startDiscovery()
  }
  
  func connectionManager(_ manager: ConnectionManager, didReceive data: Data, from endpointID: EndpointID, verificationHandler: @escaping (Bool) -> Void) {
    print("[Discover] connectionManager didReceive data from \(endpointID)")
  }
  
  func connectionManager(_ manager: ConnectionManager, didReceive data: Data, withID id: PayloadID, from endpointID: EndpointID) {
    print("[Discover] connectionManager didReceive data with ID \(id) from \(endpointID)")
  }
  
  func connectionManager(_ manager: ConnectionManager, didReceive data: Data, withID id: PayloadID, from endpointID: EndpointID, cancellationToken: CancellationToken) {
    print("[Discover] connectionManager didReceive data with ID \(id) and cancellation token from \(endpointID)")
  }
  
  func connectionManager(_ manager: ConnectionManager, didStartReceivingResourceWithID id: PayloadID, from endpointID: EndpointID, at localURL: URL, withName name: String, cancellationToken: CancellationToken) {
    print("[Discover] connectionManager didStartReceivingResource with ID \(id) from \(endpointID), resource name: \(name)")
  }
  
  func connectionManager(_ manager: ConnectionManager, didReceiveTransferUpdate update: TransferUpdate, from endpointID: EndpointID, forPayload payloadID: PayloadID) {
    print("[Discover] connectionManager didReceiveTransferUpdate for payload \(payloadID) from \(endpointID)")
  }
  
  func connectionManager(_ manager: ConnectionManager, didChangeTo newState: ConnectionState, for endpointID: EndpointID) {
    print("[Discover] connectionManager didChangeTo \(newState) for \(endpointID)")
  }
  
  func connectionManager(_ manager: ConnectionManager, didReceive verificationCode: String, from endpointID: EndpointID, verificationHandler: @escaping (Bool) -> Void) {
    print("[Discover] connectionManager didReceive verificationCode: \(verificationCode) from \(endpointID)")
    // For now, accept all verification codes automatically (default behavior)
    verificationHandler(true)
  }
  
  func connectionManager(_ manager: ConnectionManager, didReceive stream: InputStream, withID payloadID: PayloadID, from endpointID: EndpointID, cancellationToken token: CancellationToken) {
    print("[Discover] connectionManager didReceive stream with payload ID \(payloadID) from \(endpointID)")
    // Optionally, handle or read from the stream here
  }
}

extension Discover: DiscovererDelegate {
  func discoverer(
    _ discoverer: Discoverer, didFind endpointID: EndpointID, with context: Data) {
    // An endpoint was found, attempt to decode the context as a UTF-8 string
    if let contextString = String(data: context, encoding: .utf8) {
      // Successfully decoded context string
      print("Discovered endpoint \(endpointID) with context: \(contextString)")
      
      // Add the endpoint to the local collection if not already present
      if discoveredEndpoints[endpointID] == nil {
        discoveredEndpoints[endpointID] = contextString
      } else {
        print("Warning: Endpoint \(endpointID) was already discovered.")
      }
      
      // Optionally, notify user or update UI here
      
    } else {
      // Failed to decode context data
      print("Failed to decode context data for endpoint \(endpointID). Raw data: \(context)")
      
      // Optionally, notify user or handle error accordingly
    }
  }

  func discoverer(_ discoverer: Discoverer, didLose endpointID: EndpointID) {
    // A previously discovered endpoint has gone away
    if let removedContext = discoveredEndpoints.removeValue(forKey: endpointID) {
      print("Lost endpoint \(endpointID) with context: \(removedContext)")
      
      // Optionally, notify user or update UI here
      
    } else {
      // Edge case: endpoint was not found in the local collection
      print("Attempted to remove unknown endpoint \(endpointID). It was not in the discovered list.")
      
      // Optionally, notify user or handle this state gracefully
    }
  }
}
