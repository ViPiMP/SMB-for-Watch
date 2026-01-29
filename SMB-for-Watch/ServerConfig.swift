//
//  ServerConfig.swift
//  SMB-for-Watch
//
//  Server-Konfigurationsmodell
//

import Foundation

enum ServerProtocol: String, Codable, CaseIterable {
    case smb = "SMB"
    case nfs = "NFS"
    case ftp = "FTP"
    case webdav = "WebDAV"
    
    var displayName: String {
        switch self {
        case .smb: return "SMB/CIFS"
        case .nfs: return "NFS"
        case .ftp: return "FTP"
        case .webdav: return "WebDAV"
        }
    }
}

struct ServerConfig: Identifiable, Codable {
    var id = UUID()
    var name: String
    var protocol: ServerProtocol
    var host: String
    var port: Int
    var username: String
    var password: String
    var path: String
    var isActive: Bool = false
    
    var urlString: String {
        switch `protocol` {
        case .smb:
            return "smb://\(host):\(port)\(path)"
        case .nfs:
            return "nfs://\(host):\(port)\(path)"
        case .ftp:
            return "ftp://\(host):\(port)\(path)"
        case .webdav:
            return "http://\(host):\(port)\(path)"
        }
    }
}

class ServerConfigManager: ObservableObject {
    @Published var servers: [ServerConfig] = []
    private let storageKey = "savedServers"
    
    init() {
        loadServers()
    }
    
    func addServer(_ server: ServerConfig) {
        servers.append(server)
        saveServers()
    }
    
    func updateServer(_ server: ServerConfig) {
        if let index = servers.firstIndex(where: { $0.id == server.id }) {
            servers[index] = server
            saveServers()
        }
    }
    
    func deleteServer(_ server: ServerConfig) {
        servers.removeAll { $0.id == server.id }
        saveServers()
    }
    
    private func saveServers() {
        if let encoded = try? JSONEncoder().encode(servers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadServers() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ServerConfig].self, from: data) {
            servers = decoded
        }
    }
}
