import ActivityKit
import Foundation

struct PomoLiveAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var kind: String
        var category: String
        var species: String
        var endDate: Date
        var remainingSeconds: Int
        var isPaused: Bool
    }

    var sessionID: String
}
