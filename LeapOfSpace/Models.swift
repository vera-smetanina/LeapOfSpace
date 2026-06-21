import Foundation
import SwiftUI

struct Planet: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let gravity: Double
    let gravityDescription: String
    let difficulty: Int
    let colors: [String]
    let imageName: String

    var gradient: [Color] {
        colors.map(Color.init(hex:))
    }
}

struct ScienceQuestion: Codable, Identifiable, Hashable {
    enum AnswerStyle: String, Codable {
        case multipleChoice
        case text
    }

    let id: String
    let difficulty: Int
    let prompt: String
    let answerStyle: AnswerStyle
    let answers: [String]
    let choices: [String]?
    let imageName: String?
    let hint: String?
}

struct ScoreEntry: Codable, Identifiable {
    let id: UUID
    let playerName: String
    let planetID: String
    let planetName: String
    let streak: Int
    let duration: TimeInterval?
    let date: Date
}

enum GameScreen: Equatable {
    case home
    case choosePlanet
    case selected
    case gravity
    case astronaut
    case question
    case answer
    case loading
    case result(isCorrect: Bool)
    case movement(isUp: Bool)
    case winner
    case finish
    case newRecord
    case leaderboard
}

extension TimeInterval {
    var gameTimeText: String {
        let tenths = max(0, Int((self * 10).rounded()))
        let minutes = tenths / 600
        let seconds = (tenths % 600) / 10
        let fraction = tenths % 10
        return String(format: "%d:%02d.%d", minutes, seconds, fraction)
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
