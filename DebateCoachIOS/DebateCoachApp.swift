import SwiftData
import SwiftUI

@main
struct DebateCoachApp: App {
    @StateObject private var settings = AppSettingsStore()

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            ChatSession.self,
            ChatMessage.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }
}
