//
//  NetworkManager.swift
//  SMB-for-Watch
//
//  Netzwerk-Manager für SMB, NFS, FTP, WebDAV
//

import Foundation
import Combine

struct RemoteFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64?
    let modifiedDate: Date?
}

enum NetworkError: LocalizedError {
    case invalidURL
    case connectionFailed
    case authenticationFailed
    case fileNotFound
    case unsupportedProtocol
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .connectionFailed:
            return "Verbindung fehlgeschlagen"
        case .authenticationFailed:
            return "Authentifizierung fehlgeschlagen"
        case .fileNotFound:
            return "Datei nicht gefunden"
        case .unsupportedProtocol:
            return "Protokoll nicht unterstützt"
        case .downloadFailed:
            return "Download fehlgeschlagen"
        }
    }
}

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var isConnected = false
    @Published var currentFiles: [RemoteFile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentConfig: ServerConfig?
    
    private init() {}
    
    // Verbindung zu Server herstellen
    func connect(to config: ServerConfig) async throws {
        currentConfig = config
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            switch config.protocol {
            case .smb:
                try await connectSMB(config: config)
            case .nfs:
                try await connectNFS(config: config)
            case .ftp:
                try await connectFTP(config: config)
            case .webdav:
                try await connectWebDAV(config: config)
            }
            
            await MainActor.run {
                isConnected = true
            }
        } catch {
            await MainActor.run {
                isConnected = false
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // Dateien auflisten
    func listFiles(at path: String = "") async throws -> [RemoteFile] {
        guard let config = currentConfig else {
            throw NetworkError.connectionFailed
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let files: [RemoteFile]
            switch config.protocol {
            case .smb:
                files = try await listFilesSMB(path: path, config: config)
            case .nfs:
                files = try await listFilesNFS(path: path, config: config)
            case .ftp:
                files = try await listFilesFTP(path: path, config: config)
            case .webdav:
                files = try await listFilesWebDAV(path: path, config: config)
            }
            
            await MainActor.run {
                currentFiles = files
            }
            
            return files
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // Datei herunterladen
    func downloadFile(_ file: RemoteFile, to localURL: URL) async throws {
        guard let config = currentConfig else {
            throw NetworkError.connectionFailed
        }
        
        do {
            switch config.protocol {
            case .smb:
                try await downloadFileSMB(file: file, to: localURL, config: config)
            case .nfs:
                try await downloadFileNFS(file: file, to: localURL, config: config)
            case .ftp:
                try await downloadFileFTP(file: file, to: localURL, config: config)
            case .webdav:
                try await downloadFileWebDAV(file: file, to: localURL, config: config)
            }
        } catch {
            throw error
        }
    }
    
    // Stream für Audio-Wiedergabe
    func getFileStream(for file: RemoteFile) async throws -> URL {
        guard let config = currentConfig else {
            throw NetworkError.connectionFailed
        }
        
        // Für Audio-Streaming erstellen wir eine temporäre Datei
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(file.name)
        
        // Datei herunterladen
        try await downloadFile(file, to: tempFile)
        
        return tempFile
    }
    
    // MARK: - SMB Implementation
    
    private func connectSMB(config: ServerConfig) async throws {
        // SMB-Verbindung über URLSession
        // Hinweis: Native SMB-Unterstützung ist auf iOS/WatchOS eingeschränkt
        // Für Produktions-Apps würde man eine Bibliothek wie libsmbclient verwenden
        guard let url = URL(string: config.urlString) else {
            throw NetworkError.invalidURL
        }
        
        // Simulierte Verbindung - in Produktion würde hier echte SMB-Verbindung stehen
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 Sekunden
    }
    
    private func listFilesSMB(path: String, config: ServerConfig) async throws -> [RemoteFile] {
        // Simulierte Dateiliste
        // In Produktion: Echte SMB-Liste über Bibliothek
        return [
            RemoteFile(name: "Musik", path: "/Musik", isDirectory: true, size: nil, modifiedDate: nil),
            RemoteFile(name: "song1.mp3", path: "/song1.mp3", isDirectory: false, size: 5000000, modifiedDate: Date()),
            RemoteFile(name: "song2.mp3", path: "/song2.mp3", isDirectory: false, size: 4000000, modifiedDate: Date())
        ]
    }
    
    private func downloadFileSMB(file: RemoteFile, to localURL: URL, config: ServerConfig) async throws {
        // Simulierter Download
        // In Produktion: Echter SMB-Download
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    // MARK: - NFS Implementation
    
    private func connectNFS(config: ServerConfig) async throws {
        guard let url = URL(string: config.urlString) else {
            throw NetworkError.invalidURL
        }
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func listFilesNFS(path: String, config: ServerConfig) async throws -> [RemoteFile] {
        return [
            RemoteFile(name: "audio", path: "/audio", isDirectory: true, size: nil, modifiedDate: nil),
            RemoteFile(name: "track1.mp3", path: "/track1.mp3", isDirectory: false, size: 6000000, modifiedDate: Date())
        ]
    }
    
    private func downloadFileNFS(file: RemoteFile, to localURL: URL, config: ServerConfig) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    // MARK: - FTP Implementation
    
    private func connectFTP(config: ServerConfig) async throws {
        guard let url = URL(string: config.urlString) else {
            throw NetworkError.invalidURL
        }
        
        // FTP über URLSession
        var request = URLRequest(url: url)
        request.httpMethod = "LIST"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.connectionFailed
        }
    }
    
    private func listFilesFTP(path: String, config: ServerConfig) async throws -> [RemoteFile] {
        guard let url = URL(string: "\(config.urlString)/\(path)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "LIST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.connectionFailed
        }
        
        // Parse FTP LIST Antwort
        let listString = String(data: data, encoding: .utf8) ?? ""
        return parseFTPList(listString)
    }
    
    private func parseFTPList(_ list: String) -> [RemoteFile] {
        var files: [RemoteFile] = []
        let lines = list.components(separatedBy: .newlines)
        
        for line in lines where !line.isEmpty {
            let components = line.components(separatedBy: .whitespaces)
            if components.count >= 9 {
                let isDir = components[0].hasPrefix("d")
                let name = components[8...].joined(separator: " ")
                let size = Int64(components[4]) ?? 0
                
                files.append(RemoteFile(
                    name: name,
                    path: "/\(name)",
                    isDirectory: isDir,
                    size: isDir ? nil : size,
                    modifiedDate: nil
                ))
            }
        }
        
        return files
    }
    
    private func downloadFileFTP(file: RemoteFile, to localURL: URL, config: ServerConfig) async throws {
        guard let url = URL(string: "\(config.urlString)\(file.path)") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.downloadFailed
        }
        
        try data.write(to: localURL)
    }
    
    // MARK: - WebDAV Implementation
    
    private func connectWebDAV(config: ServerConfig) async throws {
        guard let url = URL(string: config.urlString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PROPFIND"
        request.setValue("0", forHTTPHeaderField: "Depth")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.connectionFailed
        }
    }
    
    private func listFilesWebDAV(path: String, config: ServerConfig) async throws -> [RemoteFile] {
        guard let url = URL(string: "\(config.urlString)/\(path)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PROPFIND"
        request.setValue("1", forHTTPHeaderField: "Depth")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.connectionFailed
        }
        
        // Parse WebDAV XML Antwort
        return parseWebDAVResponse(data)
    }
    
    private func parseWebDAVResponse(_ data: Data) -> [RemoteFile] {
        // Vereinfachtes WebDAV Parsing
        // In Produktion würde man XMLParser verwenden
        let xmlString = String(data: data, encoding: .utf8) ?? ""
        var files: [RemoteFile] = []
        
        // Einfaches Pattern-Matching für Demo
        if xmlString.contains("collection") {
            files.append(RemoteFile(
                name: "Musik",
                path: "/Musik",
                isDirectory: true,
                size: nil,
                modifiedDate: nil
            ))
        }
        
        return files
    }
    
    private func downloadFileWebDAV(file: RemoteFile, to localURL: URL, config: ServerConfig) async throws {
        guard let url = URL(string: "\(config.urlString)\(file.path)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.downloadFailed
        }
        
        try data.write(to: localURL)
    }
}
