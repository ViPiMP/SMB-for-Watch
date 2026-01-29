//
//  AudioPlayerView.swift
//  SMB-for-Watch
//
//  Audio-Player für Musik-Wiedergabe
//

import SwiftUI
import AVFoundation

class AudioPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentFile: RemoteFile?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    func playFile(_ file: RemoteFile, from networkManager: NetworkManager) async {
        do {
            let streamURL = try await networkManager.getFileStream(for: file)
            
            await MainActor.run {
                currentFile = file
                player = AVPlayer(url: streamURL)
                player?.play()
                isPlaying = true
                
                // Zeit-Observer für Fortschritt
                let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                    self?.currentTime = time.seconds
                    if let duration = self?.player?.currentItem?.duration.seconds, !duration.isNaN {
                        self?.duration = duration
                    }
                }
            }
        } catch {
            print("Fehler beim Abspielen: \(error)")
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func resume() {
        player?.play()
        isPlaying = true
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

struct AudioPlayerView: View {
    @StateObject private var playerManager = AudioPlayerManager()
    @ObservedObject var networkManager: NetworkManager
    let file: RemoteFile
    
    var body: some View {
        VStack(spacing: 8) {
            Text(file.name)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            if playerManager.duration > 0 {
                ProgressView(value: playerManager.currentTime, total: playerManager.duration)
                    .progressViewStyle(.linear)
                
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.caption2)
                    Spacer()
                    Text(formatTime(playerManager.duration))
                        .font(.caption2)
                }
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    if playerManager.currentTime > 5 {
                        playerManager.seek(to: max(0, playerManager.currentTime - 10))
                    } else {
                        playerManager.seek(to: 0)
                    }
                }) {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                }
                
                Button(action: {
                    if playerManager.isPlaying {
                        playerManager.pause()
                    } else {
                        if playerManager.currentFile?.id == file.id {
                            playerManager.resume()
                        } else {
                            Task {
                                await playerManager.playFile(file, from: networkManager)
                            }
                        }
                    }
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                
                Button(action: {
                    playerManager.seek(to: min(playerManager.duration, playerManager.currentTime + 10))
                }) {
                    Image(systemName: "goforward.10")
                        .font(.title3)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .onAppear {
            if playerManager.currentFile?.id != file.id {
                Task {
                    await playerManager.playFile(file, from: networkManager)
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
