import SwiftUI

struct ProfileView: View {
    @ObservedObject var user: UserStore
    var musicManager: EmolodyMusicManager?

    var openPreferences: () -> Void = {}
    var onLogout: () -> Void = {}

    var body: some View {
        NavigationView {
            ZStack {
                AppScreenBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        // بطاقة المستخدم - SHOWS REAL APPLE USER INFO
                        AppCard {
                            HStack(spacing: 12) {
                                // Apple Style Profile Image
                                if let musicManager = musicManager, musicManager.isAuthorized {
                                    // Apple ID style profile circle
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 70, height: 70)
                                        
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 30, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    // Default profile
                                    Circle()
                                        .fill(Brand.primary.opacity(0.2))
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 32, weight: .semibold))
                                                .foregroundColor(Brand.primary)
                                        )
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(getUserName())
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(Brand.textPrimary)
                                    
                                    // Show Apple ID email if connected
                                    if let musicManager = musicManager, musicManager.isAuthorized && !musicManager.appleUserEmail.isEmpty {
                                        Text(musicManager.appleUserEmail)
                                            .font(.subheadline)
                                            .foregroundColor(Brand.textSecondary)
                                    } else {
                                        Text(user.phone.isEmpty ? "—" : user.phone)
                                            .font(.subheadline)
                                            .foregroundColor(Brand.textSecondary)
                                    }
                                    
                                    // Show Apple ID status
                                    if let musicManager = musicManager, musicManager.isAuthorized {
                                        HStack {
                                            Image(systemName: "applelogo")
                                                .foregroundColor(.white)
                                                .font(.caption2)
                                            Text("Apple ID Account")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                    }
                                }
                                Spacer()
                            }
                        }

                        // التفضيلات
                        Button(action: openPreferences) {
                            HStack {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(Brand.primary)
                                Text("Music & Podcast Preferences")
                                    .font(.headline)
                                    .foregroundColor(Brand.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Brand.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .appCard()

                        // الحسابات المرتبطة
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Connected Accounts")
                                .font(.headline)
                                .foregroundColor(Brand.textPrimary)
                                .padding(.horizontal)

                            AppCard {
                                HStack {
                                    Image(systemName: "spotify")
                                        .foregroundColor(.green)
                                        .font(.system(size: 20))
                                    Text("Spotify")
                                        .font(.headline).foregroundColor(Brand.textPrimary)
                                    Spacer()
                                    Toggle("", isOn: .constant(false)).labelsHidden()
                                        .disabled(true)
                                }
                            }

                            AppCard {
                                HStack {
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.red)
                                        .font(.system(size: 20))
                                    Text("Apple Music")
                                        .font(.headline).foregroundColor(Brand.textPrimary)
                                    Spacer()
                                    // Show actual Apple Music connection status
                                    Toggle("", isOn: .constant(musicManager?.isAuthorized ?? false)).labelsHidden()
                                        .disabled(true)
                                }
                            }
                            
                            // Apple Account Details (NEW)
                            if let musicManager = musicManager, musicManager.isAuthorized {
                                AppCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Apple Account Details")
                                            .font(.headline)
                                            .foregroundColor(Brand.textPrimary)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Name:")
                                                    .font(.subheadline)
                                                    .foregroundColor(Brand.textSecondary)
                                                Text(musicManager.appleUserName)
                                                    .font(.subheadline)
                                                    .bold()
                                                    .foregroundColor(Brand.textPrimary)
                                                Spacer()
                                            }
                                            
                                            HStack {
                                                Text("Email:")
                                                    .font(.subheadline)
                                                    .foregroundColor(Brand.textSecondary)
                                                Text(musicManager.appleUserEmail)
                                                    .font(.subheadline)
                                                    .foregroundColor(Brand.textPrimary)
                                                Spacer()
                                            }
                                            
                                            HStack {
                                                Text("Status:")
                                                    .font(.subheadline)
                                                    .foregroundColor(Brand.textSecondary)
                                                HStack {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.green)
                                                        .font(.caption)
                                                    Text("Connected")
                                                        .font(.subheadline)
                                                        .foregroundColor(.green)
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // تسجيل الخروج
                        Button(role: .destructive, action: onLogout) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                Text("Logout").font(.headline)
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                        .appCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Helper to get user name - NOW USES REAL APPLE NAME
    private func getUserName() -> String {
        if let musicManager = musicManager, musicManager.isAuthorized && !musicManager.appleUserName.isEmpty {
            return musicManager.appleUserName
        } else if !user.name.isEmpty {
            return user.name
        } else {
            return "User"
        }
    }
}
