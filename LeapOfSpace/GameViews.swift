import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var game: GameStore
    @FocusState private var nameFieldIsFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 58))
                .foregroundStyle(Color(hex: "FFE347"))
            Text("THE LEAP\nOF SPACE")
                .font(.system(size: 54, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)
                .foregroundStyle(.white)
                .shadow(color: .purple, radius: 12)

            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SPACE EXPLORER NAME")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.75))
                    TextField("Type your name", text: $game.playerName)
                        .textFieldStyle(.plain)
                        .font(.title3.bold())
                        .padding(12)
                        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                        .focused($nameFieldIsFocused)
                        .onSubmit(game.play)
                }
                .frame(maxWidth: 360)
            }
            PrimaryButton("PLAY", systemImage: "play.fill", action: game.play)
            Spacer()
            Text("Science gets harder as gravity gets stronger")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
        .task {
            await Task.yield()
            nameFieldIsFocused = true
        }
    }
}

struct PlanetPickerView: View {
    @EnvironmentObject private var game: GameStore
    private let columns = [GridItem(.adaptive(minimum: 125), spacing: 18)]
    private let groups = [
        PlanetDifficultyGroup(
            difficulty: 1,
            title: "EASY",
            subtitle: "Low gravity • Easy questions",
            color: Color(hex: "62E6A7")
        ),
        PlanetDifficultyGroup(
            difficulty: 3,
            title: "MEDIUM",
            subtitle: "Medium gravity • Medium questions",
            color: Color(hex: "5EC8FF")
        ),
        PlanetDifficultyGroup(
            difficulty: 4,
            title: "HARD",
            subtitle: "High gravity • Hard questions",
            note: "Earth includes both medium and hard questions.",
            color: Color(hex: "FF9E57")
        ),
        PlanetDifficultyGroup(
            difficulty: 5,
            title: "SUPER HARD",
            subtitle: "Strongest gravity • Super-hard questions",
            color: Color(hex: "FF5C78")
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("CHOOSE YOUR PLANET")
                    .font(.largeTitle.weight(.black))
                    .multilineTextAlignment(.center)

                ForEach(groups) { group in
                    let planets = game.planets.filter { $0.difficulty == group.difficulty }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.title)
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(group.color)
                                Text(group.subtitle)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white.opacity(0.8))
                                if let note = group.note {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                            }

                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(planets) { planet in
                                    Button {
                                        game.select(planet)
                                    } label: {
                                        VStack(spacing: 4) {
                                            PlanetArt(planet: planet, size: 82)
                                            Text(planet.name)
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                            Text(planet.gravity.formatted(.number.precision(.fractionLength(2))) + " m/s²")
                                                .font(.caption.monospacedDigit())
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 800)
            .padding(.vertical)
        }
    }
}

private struct PlanetDifficultyGroup: Identifiable {
    let difficulty: Int
    let title: String
    let subtitle: String
    var note: String? = nil
    let color: Color

    var id: Int { difficulty }
}

struct SelectedPlanetView: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        if let planet = game.selectedPlanet {
            VStack(spacing: 28) {
                Text("YOU CHOSE")
                    .font(.title.bold())
                PlanetArt(planet: planet, size: 190, selected: true)
                Text(planet.name.uppercased())
                    .font(.system(size: 42, weight: .black, design: .rounded))
            }
        }
    }
}

struct GravityView: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        if let planet = game.selectedPlanet {
            ZStack {
                LinearGradient(colors: planet.gradient.map { $0.opacity(0.72) }, startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 24) {
                    PlanetArt(planet: planet, size: 150)
                    Text(planet.name.uppercased())
                        .font(.largeTitle.weight(.black))
                    GlassCard {
                        VStack(spacing: 12) {
                            Text("GRAVITY")
                                .font(.headline)
                            Text(planet.gravity.formatted(.number.precision(.fractionLength(2))) + " m/s²")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                            Text(planet.gravityDescription)
                                .font(.title3.bold())
                                .multilineTextAlignment(.center)
                        }
                    }
                    PrimaryButton("LAND ON \(planet.name.uppercased())", systemImage: "arrow.down.circle.fill", action: game.beginPlanet)
                }
            }
        }
    }
}

struct AstronautView: View {
    @EnvironmentObject private var game: GameStore
    let message: String
    let platformCount: Int

    var body: some View {
        VStack(spacing: 18) {
            Text(message)
                .font(.largeTitle.weight(.black))
                .multilineTextAlignment(.center)
            Spacer()
            Text("STREAK: \(platformCount)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color(hex: "FFE347"))
            if let planet = game.selectedPlanet {
                ZStack(alignment: .top) {
                    PlanetArt(planet: planet, size: 270)
                        .offset(y: 112)
                    AstronautArt(size: 145)
                }
                .frame(width: 320, height: 285)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: 650)
    }
}

struct QuestionView: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        if let question = game.currentQuestion {
            Button(action: game.revealAnswerScreen) {
                VStack(spacing: 24) {
                    HStack {
                        Text("QUESTION \(game.questionProgress)")
                        Spacer()
                        GameTimerView()
                    }
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color(hex: "FFE347"))
                    .frame(maxWidth: 620)
                    GlassCard {
                        VStack(spacing: 18) {
                            Text(question.prompt)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .minimumScaleFactor(0.65)
                                .multilineTextAlignment(.center)
                            ZStack {
                                Image(systemName: "atom")
                                    .font(.system(size: 72))
                                    .foregroundStyle(.cyan)
                                if let imageName = question.imageName, !imageName.isEmpty {
                                    EditableImage(name: imageName)
                                }
                            }
                            .frame(maxWidth: 260, maxHeight: 180)
                            if let hint = question.hint {
                                Text("Hint: \(hint)")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    Text("Tap anywhere when you are ready to answer")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

struct AnswerView: View {
    @EnvironmentObject private var game: GameStore
    @FocusState private var answerFieldIsFocused: Bool

    var body: some View {
        if let question = game.currentQuestion {
            VStack(spacing: 22) {
                HStack {
                    Text("QUESTION \(game.questionProgress)")
                    Spacer()
                    GameTimerView()
                }
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color(hex: "FFE347"))
                .frame(maxWidth: 620)
                Text(question.prompt)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                if question.answerStyle == .multipleChoice {
                    VStack(spacing: 12) {
                        ForEach(question.choices ?? [], id: \.self) { choice in
                            ChoiceButton(title: choice) {
                                game.submit(choice: choice)
                            }
                        }
                    }
                } else {
                    GlassCard {
                        VStack(spacing: 16) {
                            TextField("Type your answer", text: $game.typedAnswer)
                                .textFieldStyle(.plain)
                                .font(.title2.bold())
                                .padding()
                                .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 14))
                                .focused($answerFieldIsFocused)
                                .onSubmit { game.submit() }
                            Text("Small spelling mistakes are okay.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                            PrimaryButton("SUBMIT", systemImage: "paperplane.fill") { game.submit() }
                        }
                        .frame(maxWidth: 500)
                    }
                }
            }
            .task(id: question.id) {
                guard question.answerStyle == .text else { return }
                await Task.yield()
                answerFieldIsFocused = true
            }
        }
    }
}

struct LoadingView: View {
    @State private var activeDot = 0
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index == activeDot ? Color(hex: "FFE347") : .black)
                    .frame(width: 24, height: 24)
                    .scaleEffect(index == activeDot ? 1.3 : 1)
            }
        }
        .padding(32)
        .background(.white.opacity(0.8), in: Capsule())
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(260))
                activeDot = (activeDot + 1) % 4
            }
        }
    }
}

struct ResultView: View {
    @EnvironmentObject private var game: GameStore
    let isCorrect: Bool
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 120, weight: .black))
                .foregroundStyle(isCorrect ? .green : .red)
            Text(isCorrect ? "CORRECT!" : "INCORRECT")
                .font(.system(size: 54, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
                .foregroundStyle(isCorrect ? .green : .red)
            if !isCorrect, let answer = game.currentQuestion?.answers.first {
                GlassCard {
                    VStack(spacing: 8) {
                        Text("THE CORRECT ANSWER IS")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.75))
                        Text(answer)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(hex: "FFE347"))
                    }
                    .frame(maxWidth: 520)
                }
            }
        }
    }
}

struct MovementView: View {
    @EnvironmentObject private var game: GameStore
    let isUp: Bool
    @State private var astronautX: CGFloat = 0
    @State private var astronautY: CGFloat = 61
    @State private var platformVisible = false

    private var startsOnPlanet: Bool {
        game.streak == (isUp ? 1 : 0)
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                if isUp {
                    Platform(width: 180)
                        .offset(y: -50)
                        .opacity(platformVisible ? 1 : 0)
                        .scaleEffect(platformVisible ? 1 : 0.65)
                }

                if startsOnPlanet, let planet = game.selectedPlanet {
                    PlanetArt(planet: planet, size: 270)
                        .offset(y: 256)
                } else {
                    Platform(width: 180)
                        .offset(y: 130)
                }

                AstronautArt(size: 120)
                    .offset(x: astronautX, y: astronautY)
            }
            .frame(width: 360, height: 420)
            .clipped()

            Text(isUp ? "Platform \(game.streak)!" : "Oh no!")
                .font(.title.bold())
        }
        .task {
            if isUp {
                await animateJump()
            } else {
                await animateFall()
            }
        }
    }

    @MainActor
    private func animateJump() async {
        withAnimation(.spring(duration: 0.35, bounce: 0.35)) {
            platformVisible = true
        }
        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.45)) {
            astronautX = 28
            astronautY = -155
        }
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
            astronautX = 0
            astronautY = -119
        }
    }

    @MainActor
    private func animateFall() async {
        try? await Task.sleep(for: .milliseconds(180))
        guard !Task.isCancelled else { return }

        withAnimation(.easeIn(duration: 0.9)) {
            astronautY = 380
        }
    }
}

struct FinishView: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        VStack(spacing: 4) {
            Text("FINISH")
                .font(.system(size: 68, weight: .black, design: .rounded))
                .padding(34)
                .overlay(Circle().trim(from: 0, to: 0.78).stroke(Color(hex: "FFE347"), style: StrokeStyle(lineWidth: 8, dash: [5, 7])).rotationEffect(.degrees(130)))
            Checkerboard()
                .frame(width: 290, height: 46)
            Text("\(game.streak) PLATFORM\(game.streak == 1 ? "" : "S")")
                .font(.title.bold())
                .padding(.top, 28)
            Text("TIME \(game.finalTime.gameTimeText)")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(Color(hex: "FFE347"))
                .padding(.top, 8)
        }
    }
}

struct WinnerView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 110))
            Text("YOU WON!")
                .font(.system(size: 62, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
            Text("You answered every question correctly!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("\(game.streak) QUESTIONS  •  \(game.finalTime.gameTimeText)")
                .font(.headline.monospacedDigit())
        }
        .foregroundStyle(Color(hex: "FFE347"))
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.4), lineWidth: 2))
    }
}

struct NewRecordView: View {
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 95))
            Text("NEW RECORD!")
                .font(.system(size: 55, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(Color(hex: "FFE347"))
        .padding(40)
        .overlay(Circle().stroke(Color(hex: "FFE347"), style: StrokeStyle(lineWidth: 8, dash: [5, 8])))
    }
}

struct LeaderboardView: View {
    @EnvironmentObject private var game: GameStore
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("LEADERBOARD")
                    .font(.largeTitle.weight(.black))
                Text(game.selectedPlanet?.name ?? "")
                    .font(.title2.bold())
                    .foregroundStyle(Color(hex: "FFE347"))
                GlassCard {
                    VStack(spacing: 12) {
                        if game.selectedPlanetScores.isEmpty {
                            Text("No scores yet")
                        }
                        ForEach(Array(game.selectedPlanetScores.enumerated()), id: \.element.id) { index, score in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.headline.monospacedDigit())
                                    .frame(width: 30)
                                Text(score.playerName)
                                    .font(.headline)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(score.streak) platform\(score.streak == 1 ? "" : "s")")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(Color(hex: "FFE347"))
                                    Text(score.duration?.gameTimeText ?? "Time not recorded")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                            if index < game.selectedPlanetScores.count - 1 { Divider() }
                        }
                    }
                    .frame(maxWidth: 520)
                }
                HStack(spacing: 16) {
                    PrimaryButton("TRY AGAIN", systemImage: "arrow.clockwise", action: game.tryAgain)
                    PrimaryButton("HOME", systemImage: "house.fill", action: game.goHome)
                }
            }
            .padding(.vertical)
        }
    }
}

struct GameTimerView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            Label(game.currentElapsedTime.gameTimeText, systemImage: "stopwatch.fill")
        }
        .accessibilityLabel("Elapsed time \(game.currentElapsedTime.gameTimeText)")
    }
}

struct Checkerboard: View {
    let rows = 2
    let columns = 12
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width / CGFloat(columns)
            let height = proxy.size.height / CGFloat(rows)
            ForEach(0..<(rows * columns), id: \.self) { index in
                let row = index / columns
                let column = index % columns
                Rectangle()
                    .fill((row + column).isMultiple(of: 2) ? .white : .black)
                    .frame(width: width, height: height)
                    .position(x: (CGFloat(column) + 0.5) * width, y: (CGFloat(row) + 0.5) * height)
            }
        }
    }
}
