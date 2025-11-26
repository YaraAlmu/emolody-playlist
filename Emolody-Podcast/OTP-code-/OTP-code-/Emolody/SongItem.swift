import Foundation

struct SongItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let duration: String
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: SongItem, rhs: SongItem) -> Bool {
        lhs.id == rhs.id
    }
}
