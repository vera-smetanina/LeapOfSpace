import SwiftUI

@main
struct LeapOfSpaceApp: App {
    @StateObject private var game = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                #if os(macOS)
                .frame(minWidth: 430, minHeight: 600)
                #endif
        }
    }
}
