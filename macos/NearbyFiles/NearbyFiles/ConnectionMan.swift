import NearbyConnections
import UserNotifications
import AppKit

class ConnectionMan {
  let connectionManager: ConnectionManager

  init() {
    connectionManager = ConnectionManager(serviceID: "com.ridheshcybe.NearbyFiles", strategy: .cluster)
    connectionManager.delegate = self
      let center = UNUserNotificationCenter.current()
      center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
          if granted {
              print("Notification authorization granted")
          } else {
              print("Notification authorization denied")
          }
      }
  }
}

extension ConnectionMan: ConnectionManagerDelegate {
  func connectionManager(_ connectionManager: ConnectionManager,
                         didReceive verificationCode: String,
                         from endpointID: EndpointID,
                         verificationHandler: @escaping (Bool) -> Void) {
      // Optionally show the user the verification code. Your app should call this handler
      // with a value of `true` if the nearby endpoint should be trusted, or `false`
      // otherwise.
      let alert = NSAlert()
      alert.messageText = "Do you want to proceed connecting with \(endpointID)"
      alert.alertStyle = .warning
      alert.addButton(withTitle: "Yes")
      alert.addButton(withTitle: "No")
      
      alert.beginSheetModal(for: NSApplication.shared.keyWindow!) { (response) in
          switch response {
          case .alertFirstButtonReturn: // "Yes"
              Notify.shared.sendNotification(title: "Alert", body: "Initializing connection")
              verificationHandler(true)
              
          case .alertSecondButtonReturn: // "No"
              Notify.shared.sendNotification(title: "Alert", body: "Cancelling connection")
              verificationHandler(false)
          default:
              Notify.shared.sendNotification(title: "Alert", body: "Cancelling connection")
              verificationHandler(false)
          }
      }
  }

  func connectionManager(
    _ connectionManager: ConnectionManager,
    didReceive data: Data,
    withID payloadID: PayloadID, from endpointID: EndpointID) {
    // Attempt to decode data as UTF-8 string
    if let message = String(data: data, encoding: .utf8) {
      print("Received data from \(endpointID): \(message)")
      Notify.shared.sendNotification(title: "Data Received", body: "Message: \(message)")
    } else {
      print("Failed to decode data from \(endpointID)")
      Notify.shared.sendNotification(title: "Data Error", body: "Received data could not be decoded.")
    }
  }

  func connectionManager(
    _ connectionManager: ConnectionManager,
    didReceive stream: InputStream,
    withID payloadID: PayloadID, from endpointID: EndpointID,
    cancellationToken token: CancellationToken) {
    // Read from input stream safely
    DispatchQueue.global(qos: .background).async {
      stream.open()
      defer { stream.close() }
      
      let bufferSize = 1024
      var buffer = [UInt8](repeating: 0, count: bufferSize)
      var receivedData = Data()
      
      while stream.hasBytesAvailable {
        let bytesRead = stream.read(&buffer, maxLength: bufferSize)
        
        if bytesRead < 0 {
          if let error = stream.streamError {
            print("Stream error from \(endpointID): \(error.localizedDescription)")
            DispatchQueue.main.async {
              Notify.shared.sendNotification(title: "Stream Error", body: "Error receiving stream from \(endpointID).")
            }
          }
          return
        } else if bytesRead == 0 {
          // End of stream
          break
        } else {
          receivedData.append(buffer, count: bytesRead)
        }
        
        // TODO: Handle stream cancellation if supported by CancellationToken.
      }
      
      // Attempt to decode received data as UTF-8 string for notification
      if let message = String(data: receivedData, encoding: .utf8) {
        print("Stream received from \(endpointID): \(message)")
        DispatchQueue.main.async {
          Notify.shared.sendNotification(title: "Stream Received", body: "Message: \(message)")
        }
      } else {
        print("Stream received from \(endpointID) but failed to decode")
        DispatchQueue.main.async {
          Notify.shared.sendNotification(title: "Stream Error", body: "Received stream could not be decoded.")
        }
      }
    }
  }

  func connectionManager(
    _ connectionManager: ConnectionManager,
    didStartReceivingResourceWithID payloadID: PayloadID,
    from endpointID: EndpointID, at localURL: URL,
    withName name: String, cancellationToken token: CancellationToken) {
    print("Started receiving resource '\(name)' from \(endpointID) at \(localURL.path)")

    let fileManager = FileManager.default
    let exists = fileManager.fileExists(atPath: localURL.path)
    
    if !exists {
      print("File does not exist at \(localURL.path)")
      Notify.shared.sendNotification(title: "File Error", body: "Resource '\(name)' not found at expected location.")
      return
    }
    
    // Optionally check if file is readable
    if !fileManager.isReadableFile(atPath: localURL.path) {
      print("File at \(localURL.path) is not readable")
      Notify.shared.sendNotification(title: "File Error", body: "Resource '\(name)' is not readable.")
      return
    }
    
    Notify.shared.sendNotification(title: "Receiving File", body: "Started receiving '\(name)' from \(endpointID).")
  }

  func connectionManager(
    _ connectionManager: ConnectionManager,
    didReceiveTransferUpdate update: TransferUpdate,
    from endpointID: EndpointID, forPayload payloadID: PayloadID) {
    switch update {
    case .progress(let progress):
        let percent = Int(progress.fractionCompleted * 100)
        print("Transfer in progress from \(endpointID): \(percent)%")
        Notify.shared.sendNotification(title: "Transfer Progress", body: "File transfer \(percent)% complete.")
    case .success:
        print("Transfer completed from \(endpointID) for payload \(payloadID)")
        Notify.shared.sendNotification(title: "Transfer Completed", body: "File transfer from \(endpointID) completed successfully.")
    case .failure:
        print("Transfer failed from \(endpointID) for payload \(payloadID)")
        Notify.shared.sendNotification(title: "Transfer Failed", body: "File transfer from \(endpointID) failed.")
    case .canceled:
        print("Transfer cancelled from \(endpointID) for payload \(payloadID)")
        Notify.shared.sendNotification(title: "Transfer Cancelled", body: "File transfer from \(endpointID) was cancelled.")
    }
  }

  func connectionManager(
    _ connectionManager: ConnectionManager,
    didChangeTo state: ConnectionState,
    for endpointID: EndpointID) {
    switch state {
    case .connecting:
      print("Connecting to \(endpointID)...")
      Notify.shared.sendNotification(title: "Connection State", body: "Connecting to \(endpointID)...")
    case .connected:
      print("Connected to \(endpointID).")
      Notify.shared.sendNotification(title: "Connection State", body: "Connected to \(endpointID).")
    case .disconnected:
      print("Disconnected from \(endpointID).")
      Notify.shared.sendNotification(title: "Connection State", body: "Disconnected from \(endpointID).")
    case .rejected:
      print("Connection rejected by \(endpointID).")
      Notify.shared.sendNotification(title: "Connection State", body: "Connection rejected by \(endpointID).")
    @unknown default:
      print("Unknown connection state with \(endpointID).")
      Notify.shared.sendNotification(title: "Connection State", body: "Unknown connection state with \(endpointID).")
    }
  }
}
