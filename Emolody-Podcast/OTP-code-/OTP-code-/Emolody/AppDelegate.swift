import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Notify your app that Spotify redirected back
        NotificationCenter.default.post(name: NSNotification.Name("SpotifyCallback"), object: nil, userInfo: ["url": url])
        return true
    }
}
