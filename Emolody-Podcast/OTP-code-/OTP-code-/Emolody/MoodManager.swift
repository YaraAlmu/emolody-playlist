import Foundation
import SwiftUI
import Combine

class MoodManager: ObservableObject {
    static let shared = MoodManager()
    
    @Published var currentMood: UserMood = .happy
    
    private init() {} // Add private initializer
    
    func updateMood(_ mood: UserMood) {
        currentMood = mood
    }
}
