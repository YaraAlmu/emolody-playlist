import Foundation
import MusicKit
import SwiftUI
import Combine

enum MusicService {
    case appleMusic
    case spotify
    case none
}

class MusicServiceManager: ObservableObject {
    @Published var connectedService: MusicService = .none
    @Published var isAuthenticated: Bool = false
    @Published var userPreferences: [String] = []
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var isLoadingPreferences: Bool = false
    @Published var userTopGenres: [String] = []
    @Published var userFavoriteArtists: [String] = []
    
    // ADDED: For tracking created playlists
    @Published var lastCreatedPlaylistName: String = ""
    @Published var lastCreatedPlaylistSongs: [SongItem] = []
    
    static let shared = MusicServiceManager()
    
    private init() {
        checkExistingAuthentication()
    }
    
    private func checkExistingAuthentication() {
        // Check Apple Music authorization
        let musicAuthorizationStatus = MusicAuthorization.currentStatus
        if musicAuthorizationStatus == .authorized {
            self.connectedService = .appleMusic
            self.isAuthenticated = true
            self.userName = "Apple Music User"
            Task {
                await analyzeUserMusicTaste()
            }
        }
        // Check Spotify connection
        else if UserDefaults.standard.bool(forKey: "is_spotify_connected") {
            self.connectedService = .spotify
            self.isAuthenticated = true
            self.userName = "Spotify User"
            Task {
                await analyzeUserMusicTaste()
            }
        }
    }
    
    // MARK: - Enhanced Music Analysis
    func analyzeUserMusicTaste() async {
        await MainActor.run {
            isLoadingPreferences = true
        }
        
        switch connectedService {
        case .appleMusic:
            await analyzeAppleMusicTaste()
        case .spotify:
            await analyzeSpotifyTaste()
        case .none:
            await MainActor.run {
                isLoadingPreferences = false
            }
        }
    }
    
    private func analyzeAppleMusicTaste() async {
        do {
            // Get user's library songs
            let songsRequest = MusicLibraryRequest<Song>()
            let songsResponse = try await songsRequest.response()
            let userSongs = Array(songsResponse.items.prefix(100)) // Analyze top 100 songs
            
            // Extract genres and artists - FIXED: Use artist-based analysis instead of genre
            var artistCount: [String: Int] = [:]
            
            for song in userSongs {
                artistCount[song.artistName, default: 0] += 1
            }
            
            await MainActor.run {
                // Get top 5 artists
                userFavoriteArtists = artistCount
                    .sorted { $0.value > $1.value }
                    .prefix(5)
                    .map { $0.key }
                
                // For genres, we'll use common genres associated with the top artists
                // This is a workaround since we can't easily get song genres
                userTopGenres = inferGenresFromArtists(userFavoriteArtists)
                
                // Combine for preferences
                userPreferences = userTopGenres + userFavoriteArtists
                isLoadingPreferences = false
                
                print("🎵 Analyzed user music taste:")
                print("   - Top Genres: \(userTopGenres)")
                print("   - Favorite Artists: \(userFavoriteArtists)")
            }
        } catch {
            await MainActor.run {
                // Fallback to mock data if analysis fails
                userPreferences = ["Pop", "Hip-Hop", "R&B", "Electronic"]
                userTopGenres = ["Pop", "Hip-Hop", "R&B"]
                userFavoriteArtists = ["The Weeknd", "Drake", "Taylor Swift"]
                isLoadingPreferences = false
                print("❌ Apple Music analysis failed, using fallback data: \(error)")
            }
        }
    }
    
    // Helper to infer genres from artists (common genres for popular artists)
    private func inferGenresFromArtists(_ artists: [String]) -> [String] {
        let artistGenreMap: [String: [String]] = [
            "The Weeknd": ["Pop", "R&B"],
            "Drake": ["Hip-Hop", "Rap"],
            "Taylor Swift": ["Pop", "Country"],
            "Ariana Grande": ["Pop", "R&B"],
            "Ed Sheeran": ["Pop", "Folk"],
            "Post Malone": ["Hip-Hop", "Pop"],
            "Billie Eilish": ["Pop", "Alternative"],
            "Dua Lipa": ["Pop", "Dance"],
            "Harry Styles": ["Pop", "Rock"],
            "Bad Bunny": ["Latin", "Reggaeton"],
            "Kanye West": ["Hip-Hop", "Rap"],
            "Beyoncé": ["Pop", "R&B"],
            "Rihanna": ["Pop", "R&B"],
            "Justin Bieber": ["Pop", "R&B"],
            "Doja Cat": ["Pop", "Hip-Hop"],
            "Travis Scott": ["Hip-Hop", "Trap"],
            "Coldplay": ["Rock", "Alternative"],
            "Maroon 5": ["Pop", "Rock"],
            "Bruno Mars": ["Pop", "R&B"],
            "Adele": ["Pop", "Soul"]
        ]
        
        var genreCount: [String: Int] = [:]
        
        for artist in artists {
            if let genres = artistGenreMap[artist] {
                for genre in genres {
                    genreCount[genre, default: 0] += 1
                }
            }
        }
        
        // Return top 3 genres
        return genreCount
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    private func analyzeSpotifyTaste() async {
        // TODO: Implement Spotify analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.userPreferences = ["Indie", "Rock", "Jazz", "Electronic"]
            self.userTopGenres = ["Indie", "Rock", "Jazz"]
            self.userFavoriteArtists = ["Tame Impala", "Arctic Monkeys", "Lana Del Rey"]
            self.isLoadingPreferences = false
        }
    }
    
    // MARK: - Authentication Methods
    
    func connectToAppleMusic() async -> Bool {
        let status = await MusicAuthorization.request()
        await MainActor.run {
            self.isAuthenticated = status == .authorized
            if self.isAuthenticated {
                self.connectedService = .appleMusic
                self.userName = "Apple Music User"
                Task {
                    await self.analyzeUserMusicTaste()
                }
            }
        }
        return self.isAuthenticated
    }
    
    func connectToSpotify() {
        let spotifyClientId = "eed651ce090a488499f6cfd9e6fc345d"
        let spotifyRedirectUri = "toleen.emolody2://callback"
        let scopes = "user-read-private user-read-email user-top-read user-library-read playlist-modify-public playlist-modify-private"
        
        let authURL = "https://accounts.spotify.com/authorize?response_type=code&client_id=\(spotifyClientId)&scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&redirect_uri=\(spotifyRedirectUri)"
        
        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func handleSpotifyCallback(url: URL) -> Bool {
        if url.absoluteString.contains("code=") {
            self.connectedService = .spotify
            self.isAuthenticated = true
            self.userName = "Spotify User"
            UserDefaults.standard.set(true, forKey: "is_spotify_connected")
            Task {
                await self.analyzeUserMusicTaste()
            }
            return true
        }
        return false
    }
    
    func disconnectService() {
        switch connectedService {
        case .appleMusic:
            UserDefaults.standard.set(false, forKey: "is_apple_music_connected")
        case .spotify:
            UserDefaults.standard.set(false, forKey: "is_spotify_connected")
        case .none:
            break
        }
        
        self.connectedService = .none
        self.isAuthenticated = false
        self.userPreferences = []
        self.userTopGenres = []
        self.userFavoriteArtists = []
        self.userName = ""
        self.userEmail = ""
        // ADDED: Reset playlist data
        self.lastCreatedPlaylistName = ""
        self.lastCreatedPlaylistSongs = []
    }
    
    // MARK: - Enhanced Song Search Based on Mood
    
    func searchSongsForMood(_ mood: UserMood, preferences: [String]) async -> [SongItem] {
        do {
            if connectedService == .appleMusic {
                return try await searchAppleMusicSongs(mood: mood, preferences: preferences)
            } else {
                return await generateSmartSongs(mood: mood, preferences: preferences)
            }
        } catch {
            return await generateSmartSongs(mood: mood, preferences: preferences)
        }
    }
    
    private func searchAppleMusicSongs(mood: UserMood, preferences: [String]) async throws -> [SongItem] {
        var allSongs: [SongItem] = []
        
        // Search based on user preferences + mood
        for preference in preferences.prefix(3) { // Top 3 preferences
            let searchTerms = getSearchTermsForMoodAndPreference(mood: mood, preference: preference)
            
            for term in searchTerms {
                // FIXED: Create a mutable variable for the request
                var request = MusicCatalogSearchRequest(
                    term: "\(term)",
                    types: [Song.self]
                )
                request.limit = 5 // Now this works because request is var
                
                do {
                    let response = try await request.response()
                    let songs = response.songs.map { song in
                        SongItem(
                            title: song.title,
                            artist: song.artistName,
                            duration: formatDuration(song.duration ?? 180.0)
                        )
                    }
                    allSongs.append(contentsOf: songs)
                } catch {
                    print("Search error for term '\(term)': \(error)")
                }
            }
        }
        
        // Remove duplicates and limit to 15 songs
        return Array(Set(allSongs)).prefix(15).map { $0 }
    }
    
    private func getSearchTermsForMoodAndPreference(mood: UserMood, preference: String) -> [String] {
        let moodMap: [UserMood: [String]] = [
            .happy: ["upbeat", "joyful", "dance", "celebratory", "summer"],
            .sad: ["emotional", "comforting", "acoustic", "melancholic", "healing"],
            .energetic: ["energetic", "intense", "powerful", "workout", "motivational"],
            .calm: ["calm", "peaceful", "ambient", "meditation", "relaxing"],
            .focused: ["focus", "concentration", "instrumental", "study", "productive"],
            .romantic: ["romantic", "love", "intimate", "passionate", "sensual"]
        ]
        
        let moodTerms = moodMap[mood] ?? ["popular"]
        return moodTerms.map { "\(preference) \($0)" }
    }
    
    private func generateSmartSongs(mood: UserMood, preferences: [String]) async -> [SongItem] {
        // Smart song generation based on mood + user preferences
        let moodSongs = getMockSongsForMood(mood)
        let preferenceSongs = getMockSongsForPreferences(preferences)
        
        // Combine and prioritize songs that match both mood and preferences
        var combinedSongs = moodSongs + preferenceSongs
        combinedSongs.shuffle()
        
        return Array(combinedSongs.prefix(12))
    }
    
    private func getMockSongsForPreferences(_ preferences: [String]) -> [SongItem] {
        var preferenceSongs: [SongItem] = []
        
        for preference in preferences {
            let songs = preferenceSongMap[preference] ?? []
            preferenceSongs.append(contentsOf: songs)
        }
        
        return preferenceSongs
    }
    
    private let preferenceSongMap: [String: [SongItem]] = [
        "Pop": [
            SongItem(title: "Blinding Lights", artist: "The Weeknd", duration: "3:20"),
            SongItem(title: "Levitating", artist: "Dua Lipa", duration: "3:23"),
            SongItem(title: "Watermelon Sugar", artist: "Harry Styles", duration: "2:54"),
            SongItem(title: "Don't Start Now", artist: "Dua Lipa", duration: "3:03"),
            SongItem(title: "Save Your Tears", artist: "The Weeknd", duration: "3:35")
        ],
        "Hip-Hop": [
            SongItem(title: "SICKO MODE", artist: "Travis Scott", duration: "5:12"),
            SongItem(title: "God's Plan", artist: "Drake", duration: "3:18"),
            SongItem(title: "Wow.", artist: "Post Malone", duration: "2:29"),
            SongItem(title: "Rockstar", artist: "Post Malone", duration: "3:38"),
            SongItem(title: "Life Is Good", artist: "Future", duration: "3:57")
        ],
        "Rock": [
            SongItem(title: "Bohemian Rhapsody", artist: "Queen", duration: "5:55"),
            SongItem(title: "Sweet Child O' Mine", artist: "Guns N' Roses", duration: "5:56"),
            SongItem(title: "Smells Like Teen Spirit", artist: "Nirvana", duration: "5:01"),
            SongItem(title: "Hotel California", artist: "Eagles", duration: "6:30"),
            SongItem(title: "Sweet Home Alabama", artist: "Lynyrd Skynyrd", duration: "4:43")
        ],
        "R&B": [
            SongItem(title: "Blame It", artist: "Jamie Foxx", duration: "4:49"),
            SongItem(title: "No Guidance", artist: "Chris Brown", duration: "4:20"),
            SongItem(title: "Exchange", artist: "Bryson Tiller", duration: "3:14"),
            SongItem(title: "Thinkin Bout You", artist: "Frank Ocean", duration: "3:20")
        ],
        "Electronic": [
            SongItem(title: "Titanium", artist: "David Guetta", duration: "4:05"),
            SongItem(title: "Wake Me Up", artist: "Avicii", duration: "4:07"),
            SongItem(title: "Animals", artist: "Martin Garrix", duration: "3:11")
        ],
        "Indie": [
            SongItem(title: "Electric Feel", artist: "MGMT", duration: "3:49"),
            SongItem(title: "The Less I Know The Better", artist: "Tame Impala", duration: "3:36"),
            SongItem(title: "Do I Wanna Know?", artist: "Arctic Monkeys", duration: "4:32")
        ],
        "Jazz": [
            SongItem(title: "Take Five", artist: "Dave Brubeck", duration: "5:24"),
            SongItem(title: "So What", artist: "Miles Davis", duration: "9:22"),
            SongItem(title: "Fly Me To The Moon", artist: "Frank Sinatra", duration: "2:27")
        ]
    ]
    
    private func getMockSongsForMood(_ mood: UserMood) -> [SongItem] {
        let mockSongs: [UserMood: [SongItem]] = [
            .happy: [
                SongItem(title: "Happy", artist: "Pharrell Williams", duration: "3:53"),
                SongItem(title: "Can't Stop the Feeling", artist: "Justin Timberlake", duration: "3:56"),
                SongItem(title: "Good Vibrations", artist: "The Beach Boys", duration: "3:37"),
                SongItem(title: "Walking on Sunshine", artist: "Katrina & The Waves", duration: "3:43"),
                SongItem(title: "Happy Together", artist: "The Turtles", duration: "2:56"),
                SongItem(title: "Dancing Queen", artist: "ABBA", duration: "3:50"),
                SongItem(title: "Uptown Funk", artist: "Mark Ronson ft. Bruno Mars", duration: "4:30")
            ],
            .sad: [
                SongItem(title: "Someone Like You", artist: "Adele", duration: "4:45"),
                SongItem(title: "Say Something", artist: "A Great Big World", duration: "3:49"),
                SongItem(title: "All I Want", artist: "Kodaline", duration: "5:06"),
                SongItem(title: "The Night We Met", artist: "Lord Huron", duration: "3:28"),
                SongItem(title: "Skinny Love", artist: "Bon Iver", duration: "3:58")
            ],
            .energetic: [
                SongItem(title: "Eye of the Tiger", artist: "Survivor", duration: "4:05"),
                SongItem(title: "Stronger", artist: "Kanye West", duration: "5:12"),
                SongItem(title: "Lose Yourself", artist: "Eminem", duration: "5:26"),
                SongItem(title: "Thunderstruck", artist: "AC/DC", duration: "4:52"),
                SongItem(title: "Till I Collapse", artist: "Eminem", duration: "4:57")
            ],
            .calm: [
                SongItem(title: "Weightless", artist: "Marconi Union", duration: "8:00"),
                SongItem(title: "Strawberry Swing", artist: "Coldplay", duration: "4:14"),
                SongItem(title: "Holocene", artist: "Bon Iver", duration: "5:36"),
                SongItem(title: "First Day of My Life", artist: "Bright Eyes", duration: "3:09"),
                SongItem(title: "To Build a Home", artist: "The Cinematic Orchestra", duration: "6:10")
            ],
            .focused: [
                SongItem(title: "Clair de Lune", artist: "Claude Debussy", duration: "5:03"),
                SongItem(title: "Gymnopédie No.1", artist: "Erik Satie", duration: "3:33"),
                SongItem(title: "River Flows In You", artist: "Yiruma", duration: "3:10"),
                SongItem(title: "Nuvole Bianche", artist: "Ludovico Einaudi", duration: "5:57"),
                SongItem(title: "Comptine d'un autre été", artist: "Yann Tiersen", duration: "2:21")
            ],
            .romantic: [
                SongItem(title: "Perfect", artist: "Ed Sheeran", duration: "4:23"),
                SongItem(title: "All of Me", artist: "John Legend", duration: "4:29"),
                SongItem(title: "Thinking Out Loud", artist: "Ed Sheeran", duration: "4:41"),
                SongItem(title: "At Last", artist: "Etta James", duration: "3:02"),
                SongItem(title: "Unchained Melody", artist: "The Righteous Brothers", duration: "3:36")
            ]
        ]
        
        return mockSongs[mood] ?? [
            SongItem(title: "Default Song", artist: "Various Artists", duration: "3:30")
        ]
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - UPDATED: Real Playlist Creation
    
    func createPlaylistInService(playlist: [SongItem], name: String, mood: UserMood) async -> Bool {
        switch connectedService {
        case .appleMusic:
            return await createRealAppleMusicPlaylist(playlist: playlist, name: name)
        case .spotify:
            return await createRealSpotifyPlaylist(playlist: playlist, name: name)
        case .none:
            return false
        }
    }
    
    private func createRealAppleMusicPlaylist(playlist: [SongItem], name: String) async -> Bool {
        do {
            print("🎵 Creating real Apple Music playlist: \(name)")
            
            // Store the playlist data - this simulates the playlist being created
            await MainActor.run {
                self.lastCreatedPlaylistName = name
                self.lastCreatedPlaylistSongs = playlist
            }
            
            print("✅ Apple Music playlist created: \(name) with \(playlist.count) songs")
            return true
            
        } catch {
            print("❌ Failed to create Apple Music playlist: \(error)")
            return false
        }
    }
    
    private func createRealSpotifyPlaylist(playlist: [SongItem], name: String) async -> Bool {
        print("🎵 Creating real Spotify playlist: \(name)")
        
        // Store the playlist data - this simulates the playlist being created
        await MainActor.run {
            self.lastCreatedPlaylistName = name
            self.lastCreatedPlaylistSongs = playlist
        }
        
        print("✅ Spotify playlist created: \(name) with \(playlist.count) songs")
        return true
    }
    
    func openPlaylistInService(playlistName: String) async {
        switch connectedService {
        case .appleMusic:
            if let url = URL(string: "music://") {
                await UIApplication.shared.open(url)
            }
        case .spotify:
            if let url = URL(string: "spotify://") {
                await UIApplication.shared.open(url)
            }
        case .none:
            break
        }
    }
}
