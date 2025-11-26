import SwiftUI
import AuthenticationServices

struct EnterPhoneNumberView: View {
    @State private var phoneNumber: String = ""
    @State private var sending = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Spotify settings
    private let spotifyClientId = "eed651ce090a488499f6cfd9e6fc345d"
    private let spotifyRedirectUri = "toleen.emolody2://callback"

    let router: AppRouter
    let musicManager: EmolodyMusicManager
    var onContinue: (String) -> Void

    var body: some View {
        ZStack {
            // Use your existing background
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Logo - Keep your existing design
                HStack {
                    Text("Emo").foregroundColor(.green)
                        .font(.system(size: 34, weight: .bold))
                    Text("lody").foregroundColor(.black)
                        .font(.system(size: 34, weight: .bold))
                    Image(systemName: "music.note")
                        .foregroundColor(.green)
                        .font(.system(size: 24))
                }
                .padding(.bottom, 40)

                // Phone Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.headline)
                        .foregroundColor(.black)

                    TextField("+9665XXXXXXXX", text: $phoneNumber)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.phonePad)
                }
                .padding(.horizontal)

                // Send OTP Button
                Button("Send OTP") {
                    // Your existing OTP logic
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(10)
                .padding(.horizontal)

                // Separator
                HStack {
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                    Text("or continue with").foregroundColor(.gray).font(.subheadline)
                    Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                }
                .padding(.vertical, 10)

                // Spotify Button
                Button("Continue with Spotify") {
                    openSpotifyLogin()
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.11, green: 0.73, blue: 0.33))
                .cornerRadius(10)
                .padding(.horizontal)

                // Apple Sign-In - Keep your existing Apple Music integration
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleSignInWithApple(result)
                }
                .frame(height: 50)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .alert("Connection Status", isPresented: $showAlert) {
            Button("Continue") {
                // Navigate to main app after successful connection
                router.resetTo(.mainTabs)
            }
            Button("Stay Here", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SpotifyCallback"))) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                handleSpotifyCallback(url: url)
            }
        }
    }

    // MARK: - Spotify Integration
    private func openSpotifyLogin() {
        let scopes = "user-read-private user-read-email"
        let authURL = "https://accounts.spotify.com/authorize?response_type=code&client_id=\(spotifyClientId)&scope=\(scopes)&redirect_uri=\(spotifyRedirectUri)"
        
        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        } else {
            alertMessage = "Failed to open Spotify login"
            showAlert = true
        }
    }
    
    private func handleSpotifyCallback(url: URL) {
        print("Spotify callback received: \(url)")
        
        if url.absoluteString.contains("code=") {
            alertMessage = "✅ Spotify connected successfully! Welcome to Emolody."
            // Mark user as logged in
            UserDefaults.standard.set(true, forKey: "is_spotify_connected")
        } else {
            alertMessage = "❌ Spotify connection failed. Please try again."
        }
        showAlert = true
    }

    // MARK: - Apple Sign-In - Keep your existing function
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        Task {
            let success = await musicManager.handleSignInWithApple(result)
            
            await MainActor.run {
                if success {
                    alertMessage = "✅ Welcome to Emolody, \(musicManager.appleUserName)!"
                } else {
                    alertMessage = "❌ Failed to connect Apple account"
                }
                showAlert = true
            }
        }
    }
}
