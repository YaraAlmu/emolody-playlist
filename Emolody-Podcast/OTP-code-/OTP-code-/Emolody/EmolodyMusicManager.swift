import MusicKit
import SwiftUI
import Combine
import AuthenticationServices

class EmolodyMusicManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var userPlaylists: [Playlist] = []
    @Published var recentSongs: [Song] = []
    @Published var isLoading = false
    
    // User Info from Sign in with Apple
    @Published var appleUserName: String = ""
    @Published var appleUserEmail: String = ""
    @Published var appleUserID: String = ""
    
    // MARK: - Sign in with Apple
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async -> Bool {
        switch result {
        case .success(let authorization):
            return await handleAuthorizationSuccess(authorization)
        case .failure(let error):
            await handleAuthorizationFailure(error)
            return false
        }
    }
    
    private func handleAuthorizationSuccess(_ authorization: ASAuthorization) async -> Bool {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return false
        }
        
        await MainActor.run {
            // Get user's real name
            if let fullName = appleIDCredential.fullName {
                let firstName = fullName.givenName ?? ""
                let lastName = fullName.familyName ?? ""
                self.appleUserName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                
                // If no name provided, use a fallback
                if self.appleUserName.isEmpty {
                    self.appleUserName = "Apple User"
                }
            } else {
                self.appleUserName = "Apple User"
            }
            
            // Get user's email
            self.appleUserEmail = appleIDCredential.email ?? "apple_user@email.com"
            self.appleUserID = appleIDCredential.user
            
            print("✅ Sign in with Apple Success:")
            print("   - Name: \(self.appleUserName)")
            print("   - Email: \(self.appleUserEmail)")
            print("   - User ID: \(self.appleUserID)")
        }
        
        // Now request Apple Music access
        return await requestAppleMusicAccess()
    }
    
    private func handleAuthorizationFailure(_ error: Error) async {
        await MainActor.run {
            print("❌ Sign in with Apple Failed: \(error.localizedDescription)")
            self.appleUserName = ""
            self.appleUserEmail = ""
            self.appleUserID = ""
        }
    }
    
    // MARK: - Apple Music Authorization
    func requestAppleMusicAccess() async -> Bool {
        print("🎵 Requesting Apple Music authorization...")
        
        let status = await MusicAuthorization.request()
        
        await MainActor.run {
            self.isAuthorized = status == .authorized
            
            if self.isAuthorized {
                print("✅ Apple Music Authorized")
                // Fetch user's music data
                Task {
                    await self.fetchUserMusicData()
                }
            } else {
                print("❌ Apple Music Not Authorized")
            }
        }
        
        return self.isAuthorized
    }
    
    // Fetch user's music data after authorization
    private func fetchUserMusicData() async {
        do {
            let playlistRequest = MusicLibraryRequest<Playlist>()
            let playlistResponse = try await playlistRequest.response()
            
            await MainActor.run {
                self.userPlaylists = Array(playlistResponse.items)
                print("🎵 Loaded \(self.userPlaylists.count) playlists from Apple Music")
            }
        } catch {
            print("❌ Failed to fetch Apple Music data: \(error)")
        }
    }
    
    // MARK: - Music Functions
    func fetchUserPlaylists() async throws {
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        
        await MainActor.run {
            self.userPlaylists = Array(response.items)
        }
    }
    
    func searchSongsForMood(_ mood: String) async throws -> [Song] {
        let moodKeywords = getKeywordsForMood(mood)
        var allSongs: [Song] = []
        
        for keyword in moodKeywords {
            let request = MusicCatalogSearchRequest(
                term: "\(keyword) \(mood)",
                types: [Song.self]
            )
            let response = try await request.response()
            allSongs.append(contentsOf: Array(response.songs))
        }
        
        return Array(allSongs.prefix(20))
    }
    
    private func getKeywordsForMood(_ mood: String) -> [String] {
        let moodMap: [String: [String]] = [
            "happy": ["upbeat pop", "dance", "summer hits", "joyful"],
            "sad": ["comforting", "acoustic", "emotional", "healing"],
            "angry": ["cathartic rock", "intense", "powerful", "release"],
            "anxious": ["calming", "meditation", "peaceful", "ambient"],
            "tired": ["energy boost", "motivational", "uplifting", "wake up"],
            "relaxed": ["chill", "jazz", "lo-fi", "calm"]
        ]
        return moodMap[mood] ?? ["popular"]
    }
}
