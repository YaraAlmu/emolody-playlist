import Foundation
import SwiftUI
import Combine

class PlaylistGenerator: ObservableObject {
    @Published var generatedPlaylist: [SongItem] = []
    @Published var isLoading: Bool = false
    @Published var generatedPlaylistID: String? = nil
    @Published var lastGenerationMood: UserMood? = nil
    
    private let musicServiceManager = MusicServiceManager.shared
    
    func generatePlaylist(for mood: UserMood) async {
        await MainActor.run {
            isLoading = true
            generatedPlaylist = []
        }
        
        // Use both user preferences and mood analysis
        let userPreferences = musicServiceManager.userPreferences
        let songs = await musicServiceManager.searchSongsForMood(mood, preferences: userPreferences)
        
        await MainActor.run {
            generatedPlaylist = songs
            isLoading = false
            lastGenerationMood = mood
            generatedPlaylistID = "\(mood.rawValue.lowercased())_\(Date().timeIntervalSince1970)"
            print("🎵 Generated \(songs.count) songs for \(mood.rawValue) mood")
            print("   - User preferences: \(userPreferences)")
        }
    }
    
    func savePlaylistToService() async -> Bool {
        guard !generatedPlaylist.isEmpty,
              let playlistID = generatedPlaylistID,
              let mood = lastGenerationMood else {
            return false
        }
        
        let playlistName = "Emolody \(mood.rawValue) Playlist"
        let success = await musicServiceManager.createPlaylistInService(
            playlist: generatedPlaylist,
            name: playlistName,
            mood: mood
        )
        
        if success {
            // Show instructions for user
            await MainActor.run {
                print("✅ Playlist saved successfully!")
            }
        }
        
        return success
    }
    
    func sharePlaylist() {
        guard !generatedPlaylist.isEmpty else { return }
        
        let playlistText = generatedPlaylist.enumerated().map { (index, song) in
            "\(index + 1). \(song.title) - \(song.artist) (\(song.duration))"
        }.joined(separator: "\n")
        
        let shareText = """
        🎵 My Emolody Playlist - \(lastGenerationMood?.rawValue ?? "Mood") 🎵
        
        \(playlistText)
        
        Generated with Emolody App
        """
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
}
