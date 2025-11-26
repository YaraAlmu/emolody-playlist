import SwiftUI

struct MoodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var moodManager: MoodManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(UserMood.allCases, id: \.self) { mood in
                        Button {
                            moodManager.updateMood(mood)
                            dismiss()
                        } label: {
                            VStack {
                                Image(systemName: getMoodIcon(mood))
                                    .font(.system(size: 40))
                                    .foregroundColor(getMoodColor(mood))
                                
                                Text(mood.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            .frame(height: 120)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 3)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Your Mood")
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
    
    private func getMoodIcon(_ mood: UserMood) -> String {
        switch mood {
        case .happy: return "face.smiling"
        case .sad: return "face.dashed"
        case .energetic: return "bolt.heart"
        case .calm: return "leaf"
        case .focused: return "brain.head.profile"
        case .romantic: return "heart"
        }
    }
    
    private func getMoodColor(_ mood: UserMood) -> Color {
        switch mood {
        case .happy: return .yellow
        case .sad: return .blue
        case .energetic: return .orange
        case .calm: return .green
        case .focused: return .purple
        case .romantic: return .pink
        }
    }
}
