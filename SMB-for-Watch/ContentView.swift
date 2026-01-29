//
//  ContentView.swift
//  SMB-for-Watch
//
//  Hauptansicht der App
//

import SwiftUI

struct ContentView: View {
    @StateObject private var serverConfigManager = ServerConfigManager()
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var downloadManager = DownloadManager.shared
    
    @State private var selectedServer: ServerConfig?
    @State private var showServerList = true
    @State private var showAddServer = false
    
    var body: some View {
        TabView {
            // Server-Liste
            ServerListView(
                serverConfigManager: serverConfigManager,
                networkManager: networkManager,
                selectedServer: $selectedServer,
                showAddServer: $showAddServer
            )
            .tabItem {
                Label("Server", systemImage: "server.rack")
            }
            
            // Datei-Browser
            if networkManager.isConnected, let _ = selectedServer {
                FileBrowserView(
                    networkManager: networkManager,
                    downloadManager: downloadManager
                )
                .tabItem {
                    Label("Dateien", systemImage: "folder")
                }
            } else {
                VStack {
                    Image(systemName: "server.rack")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Keine Verbindung")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Wähle einen Server aus")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .tabItem {
                    Label("Dateien", systemImage: "folder")
                }
            }
            
            // Downloads
            DownloadsView(downloadManager: downloadManager)
                .tabItem {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
        }
        .sheet(isPresented: $showAddServer) {
            AddServerView(serverConfigManager: serverConfigManager)
        }
    }
}

struct ServerListView: View {
    @ObservedObject var serverConfigManager: ServerConfigManager
    @ObservedObject var networkManager: NetworkManager
    @Binding var selectedServer: ServerConfig?
    @Binding var showAddServer: Bool
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(serverConfigManager.servers) { server in
                    ServerRowView(
                        server: server,
                        isConnected: networkManager.isConnected && selectedServer?.id == server.id,
                        onConnect: {
                            Task {
                                selectedServer = server
                                do {
                                    try await networkManager.connect(to: server)
                                } catch {
                                    print("Verbindungsfehler: \(error)")
                                }
                            }
                        },
                        onDisconnect: {
                            networkManager.isConnected = false
                            selectedServer = nil
                        }
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        serverConfigManager.deleteServer(serverConfigManager.servers[index])
                    }
                }
            }
            .navigationTitle("Server")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddServer = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct ServerRowView: View {
    let server: ServerConfig
    let isConnected: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(server.name)
                    .font(.headline)
                Spacer()
                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Text("\(server.protocol.displayName) - \(server.host)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: isConnected ? onDisconnect : onConnect) {
                Text(isConnected ? "Trennen" : "Verbinden")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

struct AddServerView: View {
    @ObservedObject var serverConfigManager: ServerConfigManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedProtocol: ServerProtocol = .smb
    @State private var host = ""
    @State private var port = "445"
    @State private var username = ""
    @State private var password = ""
    @State private var path = "/"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Server-Informationen") {
                    TextField("Name", text: $name)
                    
                    Picker("Protokoll", selection: $selectedProtocol) {
                        ForEach(ServerProtocol.allCases, id: \.self) { protocol in
                            Text(protocol.displayName).tag(protocol)
                        }
                    }
                    
                    TextField("Host", text: $host)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section("Authentifizierung") {
                    TextField("Benutzername", text: $username)
                        .autocapitalization(.none)
                    
                    SecureField("Passwort", text: $password)
                }
                
                Section("Pfad") {
                    TextField("Pfad", text: $path)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Server hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        let config = ServerConfig(
                            name: name.isEmpty ? host : name,
                            protocol: selectedProtocol,
                            host: host,
                            port: Int(port) ?? 445,
                            username: username,
                            password: password,
                            path: path
                        )
                        serverConfigManager.addServer(config)
                        dismiss()
                    }
                    .disabled(name.isEmpty || host.isEmpty)
                }
            }
        }
    }
}

struct DownloadsView: View {
    @ObservedObject var downloadManager: DownloadManager
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(downloadManager.downloads) { download in
                    DownloadRowView(download: download)
                }
                
                Section("Lokale Dateien") {
                    ForEach(downloadManager.getLocalFiles(), id: \.self) { url in
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(url.lastPathComponent)
                                .font(.caption)
                            Spacer()
                            Button(action: {
                                downloadManager.deleteLocalFile(url)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
        }
    }
}

struct DownloadRowView: View {
    let download: DownloadTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(download.file.name)
                .font(.caption)
            
            HStack {
                switch download.status {
                case .downloading:
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Lädt...")
                        .font(.caption2)
                        .foregroundColor(.gray)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Abgeschlossen")
                        .font(.caption2)
                        .foregroundColor(.gray)
                case .failed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(download.error ?? "Fehler")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
