import SwiftUI
import MusicKit

struct PlaylistView: View {
    @StateObject private var moodManager = MoodManager.shared
    @StateObject private var musicServiceManager = MusicServiceManager.shared
    @StateObject private var playlistGenerator = PlaylistGenerator()
    
    @State private var showingServiceSelection = false
    @State private var showingMoodSelection = false
    @State private var showingSaveSuccess = false
    @State private var saveError: String? = nil
    @State private var isGenerating = false
    
    var body: some View {
        ZStack {
            // Modern gradient background matching your app
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1019607857, green: 0.2784313858, blue: 0.400000006, alpha: 1)), Color(#colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1))]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with mood
                    moodHeaderCard
                    
                    // Music Service Status
                    serviceStatusCard
                    
                    // Generate Button
                    generateButtonCard
                    
                    // Playlist Content
                    if !playlistGenerator.generatedPlaylist.isEmpty {
                        playlistContentCard
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Your Playlist")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingServiceSelection) {
            ServiceSelectionView()
        }
        .sheet(isPresented: $showingMoodSelection) {
            MoodSelectionView()
        }
        // UPDATED: Better success alert with Open option
        .alert("Playlist Created Successfully", isPresented: $showingSaveSuccess) {
            Button("Open in \(musicServiceManager.connectedService == .appleMusic ? "Apple Music" : "Spotify")") {
                Task {
                    await musicServiceManager.openPlaylistInService(playlistName: "Emolody \(moodManager.currentMood.rawValue) Playlist")
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your 'Emolody \(moodManager.currentMood.rawValue) Playlist' has been created successfully! You can now open it in \(musicServiceManager.connectedService == .appleMusic ? "Apple Music" : "Spotify").")
        }
        .alert("Save Failed", isPresented: .constant(saveError != nil)) {
            Button("OK", role: .cancel) {
                saveError = nil
            }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
    }
    
    // MARK: - Beautiful Card Components
    
    private var moodHeaderCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Mood Playlist")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You are feeling:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Image(systemName: getMoodIcon())
                            .font(.title2)
                            .foregroundColor(getMoodColor())
                        
                        Text(moodManager.currentMood.rawValue)
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundColor(getMoodColor())
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingMoodSelection = true
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var serviceStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: getServiceIcon())
                    .font(.title2)
                    .foregroundColor(getServiceColor())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(getServiceStatusText())
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !musicServiceManager.userName.isEmpty {
                        Text(musicServiceManager.userName)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                Button(musicServiceManager.isAuthenticated ? "Switch" : "Connect") {
                    showingServiceSelection = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(12)
            }
            
            if musicServiceManager.isAuthenticated {
                if musicServiceManager.isLoadingPreferences {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Loading your music preferences...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else if !musicServiceManager.userPreferences.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Music Preferences:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        FlexibleTagView(tags: musicServiceManager.userPreferences)
                    }
                }
            } else {
                Text("Connect a music service to generate personalized playlists")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var generateButtonCard: some View {
        Button(action: {
            Task {
                isGenerating = true
                await playlistGenerator.generatePlaylist(for: moodManager.currentMood)
                isGenerating = false
            }
        }) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                        .font(.title2)
                }
                
                Text(playlistGenerator.generatedPlaylist.isEmpty ? "Generate Mood Playlist" : "Regenerate Playlist")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [getMoodColor().opacity(0.8), getMoodColor()]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: getMoodColor().opacity(0.3), radius: 10, y: 5)
        }
        .disabled(isGenerating || !musicServiceManager.isAuthenticated)
        .opacity(musicServiceManager.isAuthenticated ? 1.0 : 0.6)
    }
    
    private var playlistContentCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Your Generated Playlist")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: playlistGenerator.sharePlaylist) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(playlistGenerator.generatedPlaylist.enumerated()), id: \.element.id) { index, song in
                    SongRow(song: song, index: index + 1)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Save to \(getServiceName())") {
                    Task {
                        let success = await playlistGenerator.savePlaylistToService()
                        if success {
                            showingSaveSuccess = true
                        } else {
                            saveError = "Failed to save playlist. Please try again."
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(getServiceColor())
                .cornerRadius(12)
                .shadow(color: getServiceColor().opacity(0.3), radius: 5, y: 3)
                
                Button("Open in \(getServiceName())") {
                    Task {
                        await musicServiceManager.openPlaylistInService(playlistName: "Emolody \(moodManager.currentMood.rawValue) Playlist")
                    }
                }
                .foregroundColor(getServiceColor())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func getMoodIcon() -> String {
        switch moodManager.currentMood {
        case .happy: return "face.smiling"
        case .sad: return "face.dashed"
        case .energetic: return "bolt.heart"
        case .calm: return "leaf"
        case .focused: return "brain.head.profile"
        case .romantic: return "heart"
        }
    }
    
    private func getMoodColor() -> Color {
        switch moodManager.currentMood {
        case .happy: return .yellow
        case .sad: return .blue
        case .energetic: return .orange
        case .calm: return .green
        case .focused: return .purple
        case .romantic: return .pink
        }
    }
    
    private func getServiceIcon() -> String {
        switch musicServiceManager.connectedService {
        case .appleMusic: return "applelogo"
        case .spotify: return "music.note"
        case .none: return "music.note"
        }
    }
    
    private func getServiceColor() -> Color {
        switch musicServiceManager.connectedService {
        case .appleMusic: return .red
        case .spotify: return .green
        case .none: return .gray
        }
    }
    
    private func getServiceStatusText() -> String {
        if musicServiceManager.isAuthenticated {
            switch musicServiceManager.connectedService {
            case .appleMusic: return "Connected to Apple Music"
            case .spotify: return "Connected to Spotify"
            case .none: return "Not Connected"
            }
        } else {
            return "Connect to Music Service"
        }
    }
    
    private func getServiceName() -> String {
        switch musicServiceManager.connectedService {
        case .appleMusic: return "Apple Music"
        case .spotify: return "Spotify"
        case .none: return "Music Service"
        }
    }
}

// MARK: - Beautiful Song Row
struct SongRow: View {
    let song: SongItem
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Track number
            Text("\(index)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            // Song info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(song.duration)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct FlexibleTagView: View {
    let tags: [String]
    
    var body: some View {
        FlowLayout(alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}
