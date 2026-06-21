import SwiftUI

@main
struct BarelyNotedApp: App {
    @StateObject private var store = NotesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .font(.gentium(17))
        }
    }
}
