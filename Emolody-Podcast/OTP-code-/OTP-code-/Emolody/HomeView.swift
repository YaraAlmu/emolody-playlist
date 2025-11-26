import SwiftUI

struct HomeView: View {
    @ObservedObject var user: UserStore
    var musicManager: EmolodyMusicManager?
    var startMoodDetection: () -> Void
    var openPlaylist: (String) -> Void
    
    // FIXED: Proper environment object declaration
    @EnvironmentObject private var moodManager: MoodManager
    @EnvironmentObject private var musicServiceManager: MusicServiceManager

    var body: some View {
        ZStack {
            AppScreenBackground()

            VStack(spacing: 20) {
                // Greeting - SHOWS REAL APPLE USER NAME IF CONNECTED
                VStack(alignment: .leading, spacing: 5) {
                    Text("Hello\(getUserName())!")
                        .font(.title).bold()
                        .foregroundStyle(Brand.textPrimary)
                    Text("How are you feeling today?")
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                    
                    // Show music connection status (supports both Apple Music and Spotify)
                    if isMusicServiceConnected() {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(getConnectionStatusText())
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 40)

                Spacer()

                // Mood Detection Button
                Button(action: startMoodDetection) {
                    Text("Start\nMood Detection")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(50)
                        .background(Circle().fill(Brand.primary))
                        .shadow(radius: 10)
                }

                Spacer()

                // Last Detected Mood
                if !user.lastMood.isEmpty {
                    HStack {
                        Text("😊 \(user.lastMood)\nLast detected recently")
                            .font(.subheadline)
                            .foregroundColor(.black)
                        Spacer()
                        Button("View Playlist") {
                            openPlaylistWithMood(user.lastMood)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                    )
                    .padding(.horizontal)
                }

                // Music Stats (UPDATED - supports both services)
                if isMusicServiceConnected() {
                    VStack(spacing: 10) {
                        Text("Your Music")
                            .font(.headline)
                            .foregroundStyle(Brand.textPrimary)
                        
                        HStack {
                            VStack {
                                Text("\(getPlaylistCount())")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(getServiceColor())
                                Text("Playlists")
                                    .font(.caption)
                                    .foregroundColor(Brand.textSecondary)
                            }
                            Spacer()
                            VStack {
                                Image(systemName: getServiceIcon())
                                    .font(.title2)
                                    .foregroundColor(getServiceColor())
                                Text("Connected")
                                    .font(.caption)
                                    .foregroundColor(Brand.textSecondary)
                            }
                            Spacer()
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(Brand.textSecondary)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // Suggested (بناءً على التفضيلات لاحقًا)
                VStack(spacing: 15) {
                    SuggestedRow(title: "Happy Vibes", type: "Playlist") {
                        openPlaylistWithMood("Happy")
                    }
                    SuggestedRow(title: "Calm Moments", type: "Playlist") {
                        openPlaylistWithMood("Calm")
                    }
                    SuggestedRow(title: "Energetic Beats", type: "Playlist") {
                        openPlaylistWithMood("Energetic")
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear {
            syncMusicServices()
        }
    }
    
    // MARK: - Enhanced Helper Methods
    
    // Helper to get user name - NOW USES REAL APPLE NAME OR SPOTIFY
    private func getUserName() -> String {
        // Priority: Apple Music name > Spotify > User name
        if let musicManager = musicManager, musicManager.isAuthorized && !musicManager.appleUserName.isEmpty {
            return ", \(musicManager.appleUserName)"
        } else if !musicServiceManager.userName.isEmpty && musicServiceManager.userName != "Spotify User" {
            return ", \(musicServiceManager.userName)"
        } else if !user.name.isEmpty {
            return ", \(user.name)"
        } else {
            return ""
        }
    }
    
    // Enhanced open playlist that works with our new system
    private func openPlaylistWithMood(_ mood: String) {
        // Update the mood manager with the selected mood
        if let userMood = UserMood.allCases.first(where: { $0.rawValue == mood }) {
            moodManager.updateMood(userMood)
        }
        
        // Call the original openPlaylist to trigger tab switch
        openPlaylist(mood)
    }
    
    // Check if any music service is connected
    private func isMusicServiceConnected() -> Bool {
        return musicServiceManager.isAuthenticated || (musicManager?.isAuthorized == true)
    }
    
    // Get connection status text
    private func getConnectionStatusText() -> String {
        if musicServiceManager.connectedService == .appleMusic || musicManager?.isAuthorized == true {
            return "Connected to Apple Music"
        } else if musicServiceManager.connectedService == .spotify {
            return "Connected to Spotify"
        } else {
            return "Music Service Connected"
        }
    }
    
    // Get service-specific icon
    private func getServiceIcon() -> String {
        if musicServiceManager.connectedService == .appleMusic || musicManager?.isAuthorized == true {
            return "applelogo"
        } else if musicServiceManager.connectedService == .spotify {
            return "music.note"
        } else {
            return "music.note"
        }
    }
    
    // Get service-specific color
    private func getServiceColor() -> Color {
        if musicServiceManager.connectedService == .appleMusic || musicManager?.isAuthorized == true {
            return .red
        } else if musicServiceManager.connectedService == .spotify {
            return .green
        } else {
            return .gray
        }
    }
    
    // Get playlist count
    private func getPlaylistCount() -> Int {
        if musicServiceManager.connectedService == .appleMusic || musicManager?.isAuthorized == true {
            return musicManager?.userPlaylists.count ?? 0
        } else {
            // For Spotify or other services, use preferences count
            return musicServiceManager.userPreferences.count
        }
    }
    
    // Sync between old and new music managers
    private func syncMusicServices() {
        // If Apple Music is authorized in old manager but not in new one, sync it
        if let musicManager = musicManager,
           musicManager.isAuthorized &&
           !musicServiceManager.isAuthenticated {
            
            musicServiceManager.connectedService = .appleMusic
            musicServiceManager.isAuthenticated = true
            musicServiceManager.userName = musicManager.appleUserName
            musicServiceManager.userEmail = musicManager.appleUserEmail
            // Use the new method
            Task {
                await musicServiceManager.analyzeUserMusicTaste()
            }
        }
    }
}

struct SuggestedRow: View {
    let title: String
    let type: String
    var onOpen: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(.headline).foregroundStyle(Brand.textPrimary)
                Text(type).font(.caption).foregroundStyle(Brand.textSecondary)
            }
            Spacer()

            Button("Open", action: onOpen)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
