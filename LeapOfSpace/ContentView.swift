import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var game: GameStore

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
                case .finish:
                    FinishView()
                case .newRecord:
                    NewRecordView()
                case .leaderboard:
                    LeaderboardView()
                }
            }
            .padding()
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .animation(.easeInOut(duration: 0.35), value: game.screen)
        }
        .preferredColorScheme(.dark)
    }
}
