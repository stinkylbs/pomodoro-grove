import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct PomoStaticAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var message: String
    }

    var testID: String
}
