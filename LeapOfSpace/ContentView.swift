import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var game: GameStore
    @ObservedObject private var gameCenter = GameCenterService.shared

    var body: some View {
        ZStack {
            SpaceBackground()

            Group {
                switch game.screen {
                case .home:
                    HomeView()
                case .choosePlanet:
                    PlanetPickerView()
                case .selected:
                    SelectedPlanetView()
                case .gravity:
                    GravityView()
                case .astronaut:
                    AstronautView(message: "Ready for lift-off?", platformCount: 0)
                case .question:
                    QuestionView()
                case .answer:
                    AnswerView()
                case .loading:
                    LoadingView()
                case .result(let isCorrect):
                    ResultView(isCorrect: isCorrect)
                case .movement(let isUp):
                    MovementView(isUp: isUp)
                case .winner:
                    WinnerView()
                case .finish:
                    FinishView()
                case .newRecord:
                    NewRecordView()
                case .leaderboard:
                    LeaderboardView()
                }
            }
            .screenOuterPadding(for: game.screen)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .animation(.easeInOut(duration: 0.35), value: game.screen)
        }
        .preferredColorScheme(.dark)
        .task {
            gameCenter.authenticate()
        }
        .sheet(item: $gameCenter.authenticationViewController) { authentication in
            GameCenterAuthenticationRepresentable(viewController: authentication.viewController)
        }
        .gameCenterLeaderboardPresentation(isPresented: $gameCenter.showingLeaderboard)
    }
}

private extension View {
    @ViewBuilder
    func screenOuterPadding(for screen: GameScreen) -> some View {
        #if os(iOS)
        if screen.usesEdgeToEdgeScroll {
            self
        } else {
            padding()
        }
        #else
        padding()
        #endif
    }

    @ViewBuilder
    func gameCenterLeaderboardPresentation(isPresented: Binding<Bool>) -> some View {
        #if os(macOS)
        self
        #else
        sheet(isPresented: isPresented) {
            GameCenterDashboardView()
        }
        #endif
    }
}

private extension GameScreen {
    var usesEdgeToEdgeScroll: Bool {
        switch self {
        case .choosePlanet, .leaderboard:
            return true
        default:
            return false
        }
    }
}
