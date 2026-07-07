import Foundation
import GameKit
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class GameCenterService: NSObject, ObservableObject {
    static let shared = GameCenterService()

    @Published private(set) var isAuthenticated = GKLocalPlayer.local.isAuthenticated
    @Published private(set) var playerName = ""
    @Published var authenticationViewController: GameCenterAuthenticationView?
    @Published var showingLeaderboard = false
    @Published var presentedLeaderboardID: String?

    private let leaderboardPrefix = "com.sighmon.LeapOfSpace"
    private let achievementPrefix = "com.sighmon.LeapOfSpace.achievement"
    private var pendingLeaderboardID: String?
    private var pendingAchievementIDs = Set<String>()
    private var authenticationStarted = false
    #if os(macOS)
    private var leaderboardWindowController: NSWindowController?
    private var leaderboardDelegate: MacGameCenterWindowDelegate?
    #endif

    private override init() {
        super.init()
        refreshPlayer()
    }

    var statusText: String {
        isAuthenticated ? "Game Center: \(playerName)" : "Game Center: Not signed in"
    }

    func authenticate() {
        guard !authenticationStarted else { return }
        authenticationStarted = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    self.authenticationViewController = GameCenterAuthenticationView(viewController: viewController)
                    return
                }

                if let error {
                    print("Game Center authentication failed: \(error.localizedDescription)")
                }

                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.refreshPlayer()
                if self.isAuthenticated, let pendingLeaderboardID = self.pendingLeaderboardID {
                    self.pendingLeaderboardID = nil
                    self.showLeaderboards(leaderboardID: pendingLeaderboardID)
                }
                if self.isAuthenticated {
                    self.flushPendingAchievements()
                }
            }
        }
    }

    func showLeaderboards() {
        showLeaderboards(leaderboardID: nil)
    }

    func showDefaultLeaderboard() {
        showLeaderboards(leaderboardID: leaderboardID(for: "earth", metric: "platforms"))
    }

    func showLeaderboards(for planet: Planet, metric: String = "platforms") {
        showLeaderboards(leaderboardID: leaderboardID(for: planet.id, metric: metric))
    }

    private func showLeaderboards(leaderboardID: String?) {
        isAuthenticated = GKLocalPlayer.local.isAuthenticated
        guard isAuthenticated else {
            pendingLeaderboardID = leaderboardID
            authenticate()
            return
        }
        guard let leaderboardID else {
            presentLeaderboards(leaderboardID: nil)
            return
        }

        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { [weak self] leaderboards, error in
            Task { @MainActor in
                guard let self else { return }
                if let leaderboard = leaderboards?.first {
                    self.presentLeaderboards(leaderboardID: leaderboard.baseLeaderboardID)
                } else {
                    if let error {
                        print("Game Center leaderboard lookup failed for \(leaderboardID): \(error.localizedDescription)")
                    } else {
                        print("Game Center leaderboard lookup returned no leaderboard for \(leaderboardID)")
                    }
                    self.presentLeaderboards(leaderboardID: nil)
                }
            }
        }
    }

    private func presentLeaderboards(leaderboardID: String?) {
        guard GKLocalPlayer.local.isAuthenticated else {
            pendingLeaderboardID = leaderboardID
            authenticate()
            return
        }
        #if os(macOS)
        showMacOSLeaderboardWindow(leaderboardID: leaderboardID)
        #else
        presentedLeaderboardID = leaderboardID
        showingLeaderboard = true
        #endif
    }

    func hideLeaderboards() {
        showingLeaderboard = false
        #if os(macOS)
        leaderboardWindowController?.close()
        leaderboardWindowController = nil
        leaderboardDelegate = nil
        #endif
    }

    func submit(score: ScoreEntry, completedPlanet: Bool) {
        guard isAuthenticated else { return }

        GKLeaderboard.submitScore(
            score.streak,
            context: timeContext(for: score.duration),
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID(for: score.planetID, metric: "platforms")]
        ) { error in
            if let error {
                print("Game Center platform score submission failed: \(error.localizedDescription)")
            }
        }

        guard completedPlanet, let duration = score.duration else { return }
        GKLeaderboard.submitScore(
            Int((duration * 10).rounded()),
            context: score.streak,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID(for: score.planetID, metric: "time")]
        ) { error in
            if let error {
                print("Game Center time score submission failed: \(error.localizedDescription)")
            }
        }
    }

    func reportAchievements(_ achievements: [Achievement]) {
        let achievementIDs = achievements.map(\.id)
        guard !achievementIDs.isEmpty else { return }

        if !GKLocalPlayer.local.isAuthenticated {
            pendingAchievementIDs.formUnion(achievementIDs)
            authenticate()
            return
        }

        submitAchievements(achievementIDs)
    }

    func leaderboardID(for planetID: String, metric: String) -> String {
        "\(leaderboardPrefix).\(planetID).\(metric)"
    }

    func firstLeapAchievement() -> Achievement {
        Achievement(id: "\(achievementPrefix).firstLeap")
    }

    func recordAchievement(for planetID: String) -> Achievement {
        Achievement(id: "\(achievementPrefix).record.\(planetID)")
    }

    func allPlanetRecordsAchievement() -> Achievement {
        Achievement(id: "\(achievementPrefix).record.allPlanets")
    }

    func perfectAchievement(for planetID: String) -> Achievement {
        Achievement(id: "\(achievementPrefix).perfect.\(planetID)")
    }

    func allPlanetPerfectsAchievement() -> Achievement {
        Achievement(id: "\(achievementPrefix).perfect.allPlanets")
    }

    private func refreshPlayer() {
        let localPlayer = GKLocalPlayer.local
        playerName = localPlayer.displayName.isEmpty ? localPlayer.alias : localPlayer.displayName
    }

    private func timeContext(for duration: TimeInterval?) -> Int {
        guard let duration else { return 0 }
        return Int((duration * 10).rounded())
    }

    private func flushPendingAchievements() {
        guard !pendingAchievementIDs.isEmpty else { return }
        let achievementIDs = Array(pendingAchievementIDs)
        pendingAchievementIDs.removeAll()
        submitAchievements(achievementIDs)
    }

    private func submitAchievements(_ achievementIDs: [String]) {
        let achievements = Set(achievementIDs).map { achievementID in
            let achievement = GKAchievement(identifier: achievementID)
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = true
            return achievement
        }

        GKAchievement.report(achievements) { [weak self] error in
            if let error {
                Task { @MainActor in
                    self?.pendingAchievementIDs.formUnion(achievementIDs)
                }
                print("Game Center achievement submission failed: \(error.localizedDescription)")
            }
        }
    }

    #if os(macOS)
    private func showMacOSLeaderboardWindow(leaderboardID: String?) {
        if let leaderboardWindowController {
            leaderboardWindowController.window?.makeKeyAndOrderFront(nil)
            return
        }

        let windowSize = NSSize(width: 900, height: 720)
        let delegate = MacGameCenterWindowDelegate { [weak self] in
            Task { @MainActor in
                self?.hideLeaderboards()
            }
        }
        let viewController = makeGameCenterViewController(leaderboardID: leaderboardID)
        viewController.gameCenterDelegate = delegate

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Game Center"
        window.minSize = windowSize
        window.contentViewController = viewController
        window.delegate = delegate
        window.center()

        let windowController = NSWindowController(window: window)
        leaderboardDelegate = delegate
        leaderboardWindowController = windowController
        windowController.showWindow(nil)
    }
    #endif
}

struct Achievement: Hashable {
    let id: String
}

struct GameCenterAuthenticationView: Identifiable {
    let id = UUID()
    let viewController: PlatformViewController
}

struct GameCenterDashboardView: View {
    @ObservedObject private var gameCenter = GameCenterService.shared

    var body: some View {
        GameCenterViewControllerRepresentable(leaderboardID: gameCenter.presentedLeaderboardID)
            .ignoresSafeArea()
            .onAppear {
                if !gameCenter.isAuthenticated {
                    gameCenter.authenticate()
                }
            }
    }
}

#if os(iOS)
typealias PlatformViewController = UIViewController

struct GameCenterAuthenticationRepresentable: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct GameCenterViewControllerRepresentable: UIViewControllerRepresentable {
    let leaderboardID: String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let viewController = makeGameCenterViewController(leaderboardID: leaderboardID)
        viewController.gameCenterDelegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            Task { @MainActor in
                GameCenterService.shared.hideLeaderboards()
            }
        }
    }
}
#elseif os(macOS)
typealias PlatformViewController = NSViewController

private final class MacGameCenterWindowDelegate: NSObject, GKGameCenterControllerDelegate, NSWindowDelegate {
    private let onFinish: () -> Void
    private var isFinishing = false

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        finishOnce()
    }

    func windowWillClose(_ notification: Notification) {
        finishOnce()
    }

    private func finishOnce() {
        guard !isFinishing else { return }
        isFinishing = true
        onFinish()
    }
}

struct GameCenterAuthenticationRepresentable: NSViewControllerRepresentable {
    let viewController: NSViewController

    func makeNSViewController(context: Context) -> NSViewController {
        viewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

struct GameCenterViewControllerRepresentable: NSViewControllerRepresentable {
    let leaderboardID: String?

    func makeNSViewController(context: Context) -> GKGameCenterViewController {
        makeGameCenterViewController(leaderboardID: leaderboardID)
    }

    func updateNSViewController(_ nsViewController: GKGameCenterViewController, context: Context) {}
}
#endif

private func makeGameCenterViewController(leaderboardID: String?) -> GKGameCenterViewController {
    if let leaderboardID {
        return GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
    }
    return GKGameCenterViewController(state: .leaderboards)
}
