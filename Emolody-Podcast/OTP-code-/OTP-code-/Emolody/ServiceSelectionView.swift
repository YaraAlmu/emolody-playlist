import SwiftUI

struct ServiceSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var musicServiceManager: MusicServiceManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Connect Music Service")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                // Apple Music Option
                Button {
                    Task {
                        await musicServiceManager.connectToAppleMusic()
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title2)
                        Text("Connect Apple Music")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                
                // Spotify Option
                Button {
                    musicServiceManager.connectToSpotify()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.title2)
                        Text("Connect Spotify")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Music Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
