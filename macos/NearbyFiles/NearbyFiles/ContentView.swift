import SwiftUI

struct ContentView: View {
    @State private var isAdvertising = false
    @State private var isDiscovering = false
    @State private var connectedDevices: [String] = []
    @State private var discoveredDevices: [String] = ["John’s iPhone", "Office iPad", "Anna’s MacBook"]
    @State private var showSendSheet = false
    @State private var statusMessage = "Ready to connect"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Namespace private var cardAnimation
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.7), Color(.systemBlue)]),
                    center: .center,
                    startRadius: 10,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 52, weight: .bold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue)
                            .shadow(radius: 5)
                        Text("Nearby Connections")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)
                            .shadow(radius: 2)
                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .padding(.bottom, 16)

                    HStack(spacing: 20) {
                        Button(action: {
                            withAnimation { isAdvertising.toggle() }
                            statusMessage = isAdvertising ? "Advertising..." : "Stopped advertising"
                        }) {
                            Label(isAdvertising ? "Stop Advertising" : "Advertise", systemImage: "antenna.radiowaves.left.and.right")
                                .labelStyle(VerticalLabelStyle())
                                .frame(width: 100, height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 20).fill(isAdvertising ? Color.green : Color.blue.opacity(0.7))
                                )
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }

                        Button(action: {
                            withAnimation { isDiscovering.toggle() }
                            statusMessage = isDiscovering ? "Discovering..." : "Stopped discovering"
                        }) {
                            Label(isDiscovering ? "Stop Discovering" : "Discover", systemImage: "magnifyingglass.circle")
                                .labelStyle(VerticalLabelStyle())
                                .frame(width: 100, height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 20).fill(isDiscovering ? Color.orange : Color.purple.opacity(0.7))
                                )
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                    }

                    if isDiscovering || !discoveredDevices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Nearby Devices")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                if isDiscovering {
                                    ProgressView()
                                }
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(discoveredDevices, id: \ .self) { device in
                                        VStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color(.black).opacity(0.95))
                                                    .frame(width: 110, height: 110)
                                                    .shadow(radius: 3)
                                                Image(systemName: "iphone.gen2")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 42, height: 42)
                                                    .foregroundColor(.blue)
                                            }
                                            Text(device)
                                                .font(.subheadline.weight(.medium))
                                                .lineLimit(1)
                                                .foregroundColor(.secondary)
                                            Button(action: {
                                                withAnimation { connectedDevices.append(device) }
                                                statusMessage = "Connected to \(device)"
                                                alertMessage = "Connected to \(device) successfully!"
                                                showAlert = true
                                            }) {
                                                Text("Connect")
                                                    .padding(.horizontal, 16).padding(.vertical, 6)
                                                    .background(Capsule().fill(Color.blue.opacity(0.85)))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding(6)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                        .padding(.horizontal)
                    }

                    if !connectedDevices.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Connected Devices")
                                .font(.headline)
                                .foregroundColor(.primary)
                            ForEach(connectedDevices, id: \ .self) { device in
                                HStack {
                                    Image(systemName: "link.circle.fill")
                                        .foregroundColor(.green)
                                    Text(device)
                                        .font(.body)
                                    Spacer()
                                    Button(action: { showSendSheet = true }) {
                                        Label("Send File", systemImage: "paperplane.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding([.horizontal, .top])
                    }

                    Spacer(minLength: 60)
                }
                .padding(.top, 36)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Nearby Files")
                            .font(.headline.bold())
                            .foregroundColor(.primary)
                    }
                }
                .sheet(isPresented: $showSendSheet) {
                    SendFileSheet()
                }
                .alert(alertMessage, isPresented: $showAlert) {
                    Button("OK", role: .cancel) { showAlert = false }
                }
            }
        }
    }
}

struct SendFileSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedFile: String = ""
    @State private var isSending = false
    @State private var sendSuccess = false
    var body: some View {
        VStack(spacing: 24) {
            Text("Send File")
                .font(.title.bold())
                .padding(.top)
            VStack(spacing: 14) {
                Button(action: {
                    // Present file picker in real app
                    selectedFile = "DemoPhoto.jpg"
                }) {
                    Label(selectedFile.isEmpty ? "Choose File" : selectedFile, systemImage: "doc")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemGray)))
                }

                if isSending {
                    ProgressView("Sending...")
                        .padding(.top, 6)
                } else if sendSuccess {
                    Label("Sent!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .padding(.top, 6)
                }
            }
            .padding()

            Button(action: {
                guard !selectedFile.isEmpty else { return }
                isSending = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isSending = false
                    sendSuccess = true
                }
            }) {
                Text("Send")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(selectedFile.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .disabled(selectedFile.isEmpty || isSending)
            .padding(.horizontal)

            Spacer()
            Button("Close") { dismiss() }
                .padding(.bottom)
        }
        .padding()
    }
}

struct VerticalLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

#Preview {
    ContentView()
}
