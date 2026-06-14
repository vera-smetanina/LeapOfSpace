import SwiftUI

@main
struct LeapOfSpaceApp: App {
    @StateObject private var game = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .frame(minWidth: 360, minHeight: 600)
        }
    }
}
