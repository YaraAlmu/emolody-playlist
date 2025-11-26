import SwiftUI

@main
struct EmolodyApp: App {
    @StateObject private var musicServiceManager = MusicServiceManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(musicServiceManager)
                .onOpenURL { url in
                    // Handle Spotify callback - KEEP YOUR EXISTING CODE
                    if url.absoluteString.contains("toleen.emolody2://callback") {
                        // Option 1: Let both systems handle it (recommended)
                        let success = musicServiceManager.handleSpotifyCallback(url: url)
                        
                        // ALSO keep your existing notification for EnterPhoneNumberView
                        NotificationCenter.default.post(
                            name: NSNotification.Name("SpotifyCallback"),
                            object: nil,
                            userInfo: ["url": url]
                        )
                        
                        print("Spotify callback handled by both systems: \(success ? "Success" : "Failed")")
                    }
                }
        }
    }
}
