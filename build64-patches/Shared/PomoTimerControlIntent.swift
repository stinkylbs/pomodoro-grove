import AppIntents

@available(iOS 17.0, *)
struct PomoTimerControlIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause or resume PomoLand"
    static var description = IntentDescription("Pause or resume the current PomoLand timer.")

    @Parameter(title: "PomoLand Timer ID")
    var liveID: String

    init() {}
    init(liveID: String) { self.liveID = liveID }

    @MainActor
    func perform() async throws -> some IntentResult {
        await togglePomoTimer()
        return .result()
    }
}
