//
//  FileBrowserView.swift
//  SMB-for-Watch
//
//  Datei-Browser für entfernte Server
//

import SwiftUI

struct FileBrowserView: View {
    @ObservedObject var networkManager: NetworkManager
    @ObservedObject var downloadManager: DownloadManager
    @StateObject private var playerManager = AudioPlayerManager()
    
    @State private var currentPath: String = ""
    @State private var selectedFile: RemoteFile?
    @State private var showPlayer = false
    
    private let audioExtensions = ["mp3", "m4a", "aac", "wav", "flac", "ogg"]
    
    var body: some View {
        NavigationStack {
            if networkManager.isLoading {
                ProgressView("Lade Dateien...")
            } else if networkManager.currentFiles.isEmpty {
                VStack {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Keine Dateien gefunden")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                List(networkManager.currentFiles) { file in
                    FileRowView(
                        file: file,
                        onTap: {
                            if file.isDirectory {
                                Task {
                                    try? await networkManager.listFiles(at: file.path)
                                }
                            } else if isAudioFile(file) {
                                selectedFile = file
                                showPlayer = true
                            }
                        },
                        onDownload: {
                            Task {
                                await downloadManager.downloadFile(file, from: networkManager)
                            }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showPlayer) {
            if let file = selectedFile {
                AudioPlayerView(
                    networkManager: networkManager,
                    file: file
                )
            }
        }
        .onAppear {
            Task {
                try? await networkManager.listFiles()
            }
        }
    }
    
    private func isAudioFile(_ file: RemoteFile) -> Bool {
        let ext = (file.name as NSString).pathExtension.lowercased()
        return audioExtensions.contains(ext)
    }
}

struct FileRowView: View {
    let file: RemoteFile
    let onTap: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundColor(file.isDirectory ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.caption)
                        .lineLimit(1)
                    
                    if let size = file.size, !file.isDirectory {
                        Text(formatSize(size))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if !file.isDirectory {
                    Button(action: onDownload) {
                        Image(systemName: "arrow.down.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
