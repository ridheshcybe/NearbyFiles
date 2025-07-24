//
//  advertise.swift
//  NearbyFiles
//
//  Created by ridhesh on 24/07/25.
//

import NearbyConnections
import Foundation

class Advertise {
  let connectionManager: ConnectionManager
  let advertiser: Advertiser
  let maxConnections = 5

  init(name: String?) {
    connectionManager = ConnectionManager(serviceID: "com.ridheshcybe.NearbyFiles", strategy: .cluster)

    advertiser = Advertiser(connectionManager: connectionManager)
      connectionManager.delegate = self
    advertiser.delegate = self
      let Advertisingname = (name ?? "Default Device").data(using: .utf8)!

      advertiser.startAdvertising(using: Advertisingname)
  }

  // Keep track of current connections count (assume connectionManager provides this info)
  private var currentConnections = 0
}

extension Advertise: AdvertiserDelegate {
  func advertiser(
    _ advertiser: Advertiser,
    didReceiveConnectionRequestFrom endpointID: EndpointID,
    with context: Data,
    connectionRequestHandler: @escaping (Bool) -> Void
  ) {
    // Attempt to decode context as UTF-8 string for inspection
    let contextString: String?
    if let decodedString = String(data: context, encoding: .utf8) {
      contextString = decodedString
      print("Received connection request from endpoint \(endpointID) with context: \(decodedString)")
    } else {
      contextString = nil
      print("Failed to decode context data from endpoint \(endpointID). Rejecting connection.")
      connectionRequestHandler(false)
      return
    }

    // Example edge case: reject connection if context contains banned keyword
    if let ctx = contextString, ctx.contains("banned") {
      print("Connection request from endpoint \(endpointID) rejected due to banned keyword in context.")
      connectionRequestHandler(false)
      return
    }

    // Example edge case: reject if max connections reached
    if currentConnections >= maxConnections {
      print("Maximum connections reached. Rejecting connection request from endpoint \(endpointID).")
      connectionRequestHandler(false)
      return
    }

    // Accept the connection request
    connectionRequestHandler(true)
    print("Accepted connection request from endpoint \(endpointID).")
    currentConnections += 1

    // You may want to notify user about incoming connection request and acceptance here
  }
}

extension Advertise: ConnectionManagerDelegate {
    func connectionManager(_ connectionManager: NearbyConnections.ConnectionManager, didChangeTo state: NearbyConnections.ConnectionState, for endpointID: NearbyConnections.EndpointID) {
        switch state {
        case .connected:
            currentConnections += 1
            print("Endpoint \(endpointID) connected. Current connections: \(currentConnections)")
        case .disconnected:
            currentConnections = max(0, currentConnections - 1)
            print("Endpoint \(endpointID) disconnected. Current connections: \(currentConnections)")
        default:
            print("Endpoint \(endpointID) changed state to \(state). Current connections: \(currentConnections)")
        }
        logConnectionsCount()
    }
    
    func connectionManager(_ connectionManager: NearbyConnections.ConnectionManager, didReceiveTransferUpdate update: NearbyConnections.TransferUpdate, from endpointID: NearbyConnections.EndpointID, forPayload payloadID: NearbyConnections.PayloadID) {
        // Handle transfer update
        print("Received transfer update from endpoint \(endpointID) for payload \(payloadID): \(update)")
    }
    
    func connectionManager(_ connectionManager: NearbyConnections.ConnectionManager, didStartReceivingResourceWithID payloadID: NearbyConnections.PayloadID, from endpointID: NearbyConnections.EndpointID, at localURL: URL, withName name: String, cancellationToken token: NearbyConnections.CancellationToken) {
        // Handle start receiving resource
        print("Started receiving resource '\(name)' from endpoint \(endpointID) at \(localURL)")
    }
    
    func connectionManager(_ connectionManager: NearbyConnections.ConnectionManager, didReceive stream: InputStream, withID payloadID: NearbyConnections.PayloadID, from endpointID: NearbyConnections.EndpointID, cancellationToken token: NearbyConnections.CancellationToken) {
        // Handle received stream
        print("Received stream with payload ID \(payloadID) from endpoint \(endpointID)")
    }
    
    func connectionManager(_ connectionManager: NearbyConnections.ConnectionManager, didReceive data: Data, withID payloadID: NearbyConnections.PayloadID, from endpointID: NearbyConnections.EndpointID) {
        // Handle received data
        print("Received data payload \(payloadID) from endpoint \(endpointID), size: \(data.count) bytes")
    }
    
    // Helper to log current connections count
    private func logConnectionsCount() {
        print("Current active connections: \(currentConnections)")
    }
}
