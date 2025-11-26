import SwiftUI
import AVFoundation
import Combine

// MARK: - Routes
enum Route: Hashable {
    case splash
    case enterPhone
    case verifyPhone(number: String)
    case onboardingProfile
    case cameraPermission
    case moodDetection
    case mainTabs
    case playlist(mood: String)
    case settings
    case profile
}

// MARK: - Router
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func go(_ r: Route) { path.append(r) }

    func resetTo(_ r: Route) {
        path = NavigationPath()
        path.append(r)
    }

    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path.removeLast(path.count) }
}

// MARK: - RootView
struct RootView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var camera = CameraService()
    @StateObject private var user   = UserStore()
    @StateObject private var musicManager = EmolodyMusicManager() // SINGLE INSTANCE

    var body: some View {
        NavigationStack(path: $router.path) {
            
            // البداية: Splash → EnterPhone
            SplashView(onFinished: { router.go(.enterPhone) })
                .navigationDestination(for: Route.self) { route in
                    switch route {

                    case .splash:
                        SplashView(onFinished: { router.go(.enterPhone) })

                    case .enterPhone:
                        EnterPhoneNumberView(
                            router: router,
                            musicManager: musicManager, // PASS THE SAME INSTANCE
                            onContinue: { number in
                                router.go(.verifyPhone(number: number))
                            }
                        )

                    case .verifyPhone(let number):
                        Color.clear

                    case .onboardingProfile:
                        OnboardingProfileView(user: user) {
                            router.resetTo(.mainTabs)
                        }

                    case .cameraPermission:
                        CameraPermissionView(
                            camera: camera,
                            onSkip: { router.resetTo(.mainTabs) }
                        )
                        .onChange(of: camera.isAuthorized) { ok in
                            if ok { router.go(.moodDetection) }
                        }
                        .onAppear {
                            camera.isAuthorized =
                              AVCaptureDevice.authorizationStatus(for: .video) == .authorized
                        }

                    case .moodDetection:
                        MoodDetectionView(camera: camera) {
                            let mood = camera.moodText.isEmpty ? "Happy" : camera.moodText
                            user.lastMood = mood
                            user.save()
                            router.go(.playlist(mood: mood))
                        }
                        .navigationBarTitleDisplayMode(.inline)

                    case .mainTabs:
                        MainTabView(
                            user: user,
                            musicManager: musicManager, // PASS THE SAME INSTANCE
                            openPlaylist: { mood in router.go(.playlist(mood: mood)) },
                            startMoodDetection: { router.go(.cameraPermission) },
                            openPreferences: { router.go(.onboardingProfile) },
                            logout: {
                                user.clear()
                                router.resetTo(.enterPhone)
                            }
                        )

                    case .playlist(let mood):
                        // Use the new smart PlaylistView instead of hardcoded one
                        PlaylistView()
                            .onAppear {
                                if let userMood = UserMood.allCases.first(where: { $0.rawValue == mood }) {
                                    MoodManager.shared.updateMood(userMood)
                                }
                            }
                        

                    case .settings:
                        SettingsPlaceholder()

                    case .profile:
                        ProfileView(
                            user: user,
                            musicManager: musicManager, // PASS THE SAME INSTANCE
                            openPreferences: { router.go(.onboardingProfile) },
                            onLogout: {
                                user.clear()
                                router.resetTo(.enterPhone)
                            }
                        )
                    }
                }
        }
    }
}

// MARK: - (اختياري) Placeholder بسيط للإعدادات
struct SettingsPlaceholder: View {
    var body: some View {
        ZStack {
            AppScreenBackground()
            VStack(spacing: 16) {
                Text("Settings")
                    .font(.title2.bold())
                    .foregroundStyle(Brand.textPrimary)

                Button {
                    // Settings action
                } label: {
                    Text("Edit preferences")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Brand.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
