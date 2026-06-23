import SwiftUI

struct SpaceBackground: View {
    private let stars = (0..<80).map { index in
        Star(
            x: Double((index * 47) % 997) / 997,
            y: Double((index * 83) % 991) / 991,
            size: Double((index % 3) + 1)
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "03051C"), Color(hex: "111C55"), Color(hex: "26114C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                    Circle()
                        .fill(.white.opacity(0.45 + star.size * 0.14))
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x * proxy.size.width, y: star.y * proxy.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }

    private struct Star {
        let x: Double
        let y: Double
        let size: Double
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
                    .fontWeight(.heavy)
            }
            .font(.title3)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .foregroundStyle(Color(hex: "10142E"))
            .background(Color(hex: "FFE347"), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.8), lineWidth: 2))
            .shadow(color: Color(hex: "FFE347").opacity(0.55), radius: 12)
        }
        .buttonStyle(.plain)
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.25), lineWidth: 1.5))
    }
}

struct PlanetArt: View {
    let planet: Planet
    var size: CGFloat = 120
    var selected = false

    var body: some View {
        ZStack {
            if selected {
                Circle()
                    .stroke(Color(hex: "FFE347"), style: StrokeStyle(lineWidth: 7, dash: [4, 7]))
                    .frame(width: size + 28, height: size + 28)
                    .rotationEffect(.degrees(-8))
            }

            Circle()
                .fill(LinearGradient(colors: planet.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(.white.opacity(0.22))
                        .frame(width: size * 0.3)
                        .offset(x: size * 0.17, y: size * 0.12)
                }
                .shadow(color: (planet.gradient.last ?? .white).opacity(0.7), radius: 18)

            EditableImage(name: planet.imageName)
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
        .frame(width: size + 36, height: size + 36)
        .accessibilityLabel(planet.name)
    }
}

struct EditableImage: View {
    let name: String

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
    }
}

struct AstronautArt: View {
    var body: some View {
        EditableImage(name: "astronaut")
        .frame(width: 100, height: 100)
        .shadow(color: .cyan.opacity(0.6), radius: 12)
        .accessibilityLabel("Astronaut")
    }
}

struct Platform: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
            .frame(width: 190, height: 18)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 2))
    }
}
