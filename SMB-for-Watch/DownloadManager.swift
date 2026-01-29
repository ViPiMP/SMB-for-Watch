//
//  DownloadManager.swift
//  SMB-for-Watch
//
//  Download-Manager für Dateien
//

import Foundation
import Combine

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    
    @Published var downloads: [DownloadTask] = []
    
    private let documentsDirectory: URL
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func downloadFile(_ file: RemoteFile, from networkManager: NetworkManager) async {
        let task = DownloadTask(file: file, status: .downloading)
        
        await MainActor.run {
            downloads.append(task)
        }
        
        do {
            let localURL = documentsDirectory.appendingPathComponent(file.name)
            
            // Prüfen ob Datei bereits existiert
            if FileManager.default.fileExists(atPath: localURL.path) {
                await MainActor.run {
                    if let index = downloads.firstIndex(where: { $0.id == task.id }) {
                        downloads[index].status = .completed
                        downloads[index].localURL = localURL
                    }
                }
                return
            }
            
            try await networkManager.downloadFile(file, to: localURL)
            
            await MainActor.run {
                if let index = downloads.firstIndex(where: { $0.id == task.id }) {
                    downloads[index].status = .completed
                    downloads[index].localURL = localURL
                }
            }
        } catch {
            await MainActor.run {
                if let index = downloads.firstIndex(where: { $0.id == task.id }) {
                    downloads[index].status = .failed
                    downloads[index].error = error.localizedDescription
                }
            }
        }
    }
    
    func getLocalFiles() -> [URL] {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: []
            )
            return files.filter { !$0.hasDirectoryPath }
        } catch {
            return []
        }
    }
    
    func deleteLocalFile(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

enum DownloadStatus {
    case downloading
    case completed
    case failed
}

struct DownloadTask: Identifiable {
    let id = UUID()
    let file: RemoteFile
    var status: DownloadStatus
    var localURL: URL?
    var error: String?
}
