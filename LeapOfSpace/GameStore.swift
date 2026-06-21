import Foundation

@MainActor
final class GameStore: ObservableObject {
    @Published var screen: GameScreen = .home
    @Published var playerName = ""
    @Published var selectedPlanet: Planet?
    @Published var currentQuestion: ScienceQuestion?
    @Published var typedAnswer = ""
    @Published var streak = 0
    @Published var isNewRecord = false
    @Published private(set) var finalTime: TimeInterval = 0
    @Published private(set) var planets: [Planet] = []
    @Published private(set) var scores: [ScoreEntry] = []

    private var questions: [ScienceQuestion] = []
    private var usedQuestionIDs: Set<String> = []
    private var gameStartedAt: Date?
    private var transitionTask: Task<Void, Never>?
    private let scoreKey = "leapOfSpace.scores"

    init() {
        planets = Self.load([Planet].self, file: "Planets")
        questions = Self.load([ScienceQuestion].self, file: "Questions")
        loadScores()
    }

    deinit {
        transitionTask?.cancel()
    }

    var displayName: String {
        let trimmed = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Space Explorer" : trimmed
    }

    var selectedPlanetScores: [ScoreEntry] {
        guard let selectedPlanet else { return [] }
        return scores
            .filter { $0.planetID == selectedPlanet.id }
            .sorted { lhs, rhs in
                if lhs.streak != rhs.streak {
                    return lhs.streak > rhs.streak
                }
                let lhsDuration = lhs.duration ?? .infinity
                let rhsDuration = rhs.duration ?? .infinity
                if lhsDuration != rhsDuration {
                    return lhsDuration < rhsDuration
                }
                return lhs.date < rhs.date
            }
            .prefix(10)
            .map { $0 }
    }

    var currentElapsedTime: TimeInterval {
        if finalTime > 0 {
            return finalTime
        }
        guard let gameStartedAt else { return 0 }
        return Date().timeIntervalSince(gameStartedAt)
    }

    var questionProgress: String {
        guard let selectedPlanet else { return "" }
        return "\(usedQuestionIDs.count) / \(eligibleQuestions(for: selectedPlanet).count)"
    }

    func play() {
        screen = .choosePlanet
    }

    func select(_ planet: Planet) {
        selectedPlanet = planet
        screen = .selected
        after(seconds: 2) { [weak self] in self?.screen = .gravity }
    }

    func beginPlanet() {
        streak = 0
        usedQuestionIDs = []
        gameStartedAt = nil
        finalTime = 0
        isNewRecord = false
        screen = .astronaut
        after(seconds: 2) { [weak self] in self?.prepareQuestion() }
    }

    func revealAnswerScreen() {
        typedAnswer = ""
        screen = .answer
    }

    func submit(choice: String? = nil) {
        guard let question = currentQuestion else { return }
        let response = choice ?? typedAnswer
        let correct = question.answers.contains { Self.answersMatch(response, $0) }
        let completedAllQuestions = correct && usedQuestionIDs.count == eligibleQuestionsForSelectedPlanet.count
        if !correct || completedAllQuestions {
            stopTimer()
        }
        screen = .loading

        after(seconds: 1.5) { [weak self] in
            guard let self else { return }
            self.screen = .result(isCorrect: correct)
            self.after(seconds: correct ? 1.5 : 3) { [weak self] in
                self?.showMovement(correct: correct, completedAllQuestions: completedAllQuestions)
            }
        }
    }

    func tryAgain() {
        transitionTask?.cancel()
        beginPlanet()
    }

    func goHome() {
        transitionTask?.cancel()
        selectedPlanet = nil
        currentQuestion = nil
        streak = 0
        gameStartedAt = nil
        finalTime = 0
        screen = .home
    }

    private func prepareQuestion() {
        guard let planet = selectedPlanet else { return }
        if gameStartedAt == nil {
            gameStartedAt = Date()
        }
        let pool = eligibleQuestions(for: planet).filter {
            !usedQuestionIDs.contains($0.id)
        }
        if pool.isEmpty {
            stopTimer()
            showWinner()
            return
        }
        currentQuestion = pool.randomElement()
        if let currentQuestion { usedQuestionIDs.insert(currentQuestion.id) }
        screen = .question
    }

    private func showMovement(correct: Bool, completedAllQuestions: Bool) {
        screen = .movement(isUp: correct)
        if correct {
            streak += 1
            after(seconds: 1.5) { [weak self] in
                if completedAllQuestions {
                    self?.showWinner()
                } else {
                    self?.prepareQuestion()
                }
            }
        } else {
            after(seconds: 1.5) { [weak self] in self?.completeGame() }
        }
    }

    private func showWinner() {
        screen = .winner
        after(seconds: 2.5) { [weak self] in self?.completeGame() }
    }

    private func completeGame() {
        guard let planet = selectedPlanet else { return }
        stopTimer()
        let previousScores = scores
            .filter { $0.planetID == planet.id && $0.playerName == displayName }
        isNewRecord = streak > 0 && previousScores.allSatisfy {
            streak > $0.streak ||
                (streak == $0.streak && finalTime < ($0.duration ?? .infinity))
        }
        if streak > 0 {
            scores.append(ScoreEntry(
                id: UUID(), playerName: displayName, planetID: planet.id,
                planetName: planet.name, streak: streak, duration: finalTime, date: Date()
            ))
            saveScores()
        }
        screen = .finish
        after(seconds: 1.8) { [weak self] in
            guard let self else { return }
            self.screen = self.isNewRecord ? .newRecord : .leaderboard
            if self.isNewRecord {
                self.after(seconds: 1.8) { [weak self] in self?.screen = .leaderboard }
            }
        }
    }

    private func after(seconds: Double, action: @escaping @MainActor () -> Void) {
        transitionTask?.cancel()
        transitionTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            action()
        }
    }

    private func loadScores() {
        guard let data = UserDefaults.standard.data(forKey: scoreKey) else { return }
        scores = (try? JSONDecoder().decode([ScoreEntry].self, from: data)) ?? []
    }

    private func saveScores() {
        guard let data = try? JSONEncoder().encode(scores) else { return }
        UserDefaults.standard.set(data, forKey: scoreKey)
    }

    private var eligibleQuestionsForSelectedPlanet: [ScienceQuestion] {
        guard let selectedPlanet else { return [] }
        return eligibleQuestions(for: selectedPlanet)
    }

    private func eligibleQuestions(for planet: Planet) -> [ScienceQuestion] {
        let allowedDifficulties = planet.id == "earth" ? Set([3, 4]) : Set([planet.difficulty])
        return questions.filter { allowedDifficulties.contains($0.difficulty) }
    }

    private func stopTimer() {
        guard finalTime == 0, let gameStartedAt else { return }
        finalTime = Date().timeIntervalSince(gameStartedAt)
    }

    private static func load<T: Decodable>(_ type: T.Type, file: String) -> T {
        guard let url = Bundle.main.url(forResource: file, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(type, from: data) else {
            fatalError("Could not load \(file).json. Check that its JSON is valid.")
        }
        return value
    }

    private static func answersMatch(_ response: String, _ answer: String) -> Bool {
        let lhs = normalized(response)
        let rhs = normalized(answer)
        guard !lhs.isEmpty else { return false }
        if lhs == rhs { return true }
        let allowedMistakes = rhs.count >= 8 ? 2 : (rhs.count >= 5 ? 1 : 0)
        return editDistance(lhs, rhs) <= allowedMistakes
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private static func editDistance(_ lhs: String, _ rhs: String) -> Int {
        let a = Array(lhs), b = Array(rhs)
        var previous = Array(0...b.count)
        for (i, left) in a.enumerated() {
            var current = [i + 1]
            for (j, right) in b.enumerated() {
                current.append(min(current[j] + 1, previous[j + 1] + 1, previous[j] + (left == right ? 0 : 1)))
            }
            previous = current
        }
        return previous[b.count]
    }
}
