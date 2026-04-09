
//
//  CircoDeDoblesView.swift
//  Math Foundations — Juegos
//
//  TEKS 1.3 · Dobles y Casi Dobles
//  Tarjetas de circo que se voltean revelan parejas de animales.
//  El estudiante completa la ecuación de doble o casi doble (±1).
//

import SwiftUI
import AudioToolbox

// MARK: - Models

private enum GamePhase: String, CaseIterable {
    case doubles     = "Dobles"
    case nearDoubles = "Casi Dobles"
}

private struct CircusCard: Identifiable {
    let id = UUID()
    let base: Int           // base number (e.g., 3 means 3+3)
    let delta: Int          // 0 = double, +1/-1 = near double
    var isFlipped: Bool = false
    var isSolved: Bool = false

    var leftNum: Int { base }
    var rightNum: Int { base + delta }
    var answer: Int { leftNum + rightNum }

    var emoji: String {
        let animals = ["🦁","🐘","🐯","🐧","🦒","🦓","🐬","🦜","🐻","🦊"]
        return animals[(base - 1) % animals.count]
    }

    // Visual display: repeated emojis for each side
    var leftVisual: String { String(repeating: emoji, count: leftNum) }
    var rightVisual: String { String(repeating: emoji, count: rightNum) }

    var equationDisplay: String {
        "\(leftNum) + \(rightNum) = ?"
    }
}

// MARK: - Main View

struct CircoDeDoblesView: View {
    @State private var phase: GamePhase = .doubles
    @State private var cards: [CircusCard] = []
    @State private var activeCardID: UUID? = nil
    @State private var choices: [Int] = []
    @State private var score: Int = 0
    @State private var phaseComplete: Bool = false
    @State private var wrongFlash: Bool = false
    @State private var solvedCount: Int = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top, 8)

                phaseToggle
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Card grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(cards) { card in
                            CardCell(
                                card: card,
                                isActive: card.id == activeCardID
                            )
                            .onTapGesture { handleCardTap(card) }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 14)
                }

                // Active card question + choices
                if let activeID = activeCardID,
                   let card = cards.first(where: { $0.id == activeID }) {
                    questionPanel(for: card)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: 0)
            }
            .animation(.spring(response: 0.35), value: activeCardID)
        }
        .background(circusBackground)
        .navigationTitle("El Circo de los Dobles")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { buildCards() }
        .overlay {
            if phaseComplete { phaseCompleteOverlay }
        }
    }

    // MARK: Background

    var circusBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.93, blue: 0.88),
                         Color(red: 1.0, green: 0.85, blue: 0.75)],
                startPoint: .top, endPoint: .bottom
            )
            // Circus stripes at top
            HStack(spacing: 0) {
                ForEach(0..<20) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.red.opacity(0.18) : Color.yellow.opacity(0.12))
                        .frame(width: 20)
                }
            }
            .frame(height: 10)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
    }

    // MARK: Header

    var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TEKS 1.3 · Dobles y Casi Dobles")
                    .font(.caption)
                    .foregroundColor(.secondary)
                let solved = cards.filter(\.isSolved).count
                Text("\(solved)/\(cards.count) tarjetas resueltas")
                    .font(.subheadline.bold())
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(score)")
                    .font(.title3.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.yellow.opacity(0.25))
            .cornerRadius(10)
        }
        .padding(.vertical, 6)
    }

    // MARK: Phase Toggle

    var phaseToggle: some View {
        HStack(spacing: 0) {
            ForEach(GamePhase.allCases, id: \.self) { p in
                Button {
                    if p != phase {
                        withAnimation(.spring()) {
                            phase = p
                            phaseComplete = false
                            buildCards()
                        }
                    }
                } label: {
                    Text(p.rawValue)
                        .font(.subheadline.bold())
                        .foregroundColor(phase == p ? .white : .red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(phase == p ? Color.red : Color.clear)
                }
            }
        }
        .background(Color.red.opacity(0.12))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1.5))
    }

    // MARK: Question Panel

    func questionPanel(for card: CircusCard) -> some View {
        VStack(spacing: 12) {
            // Animal visual
            VStack(spacing: 4) {
                HStack(spacing: 12) {
                    Text(card.leftVisual)
                        .font(.system(size: card.leftNum > 4 ? 18 : 24))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("+")
                        .font(.title2.bold())
                        .foregroundColor(.red)
                    Text(card.rightVisual)
                        .font(.system(size: card.rightNum > 4 ? 18 : 24))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Text(card.equationDisplay)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.9))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.07), radius: 6)

            // Choices
            HStack(spacing: 12) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        handleAnswer(choice, for: card)
                    } label: {
                        Text("\(choice)")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: .red.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }

                // Dismiss button
                Button {
                    withAnimation { activeCardID = nil }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.gray.opacity(0.6))
                        .cornerRadius(14)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground).opacity(0.95))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -4)
    }

    // MARK: Phase Complete Overlay

    var phaseCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎪")
                    .font(.system(size: 72))
                Text(phase == .doubles ? "¡Dobles Completados!" : "¡Casi Dobles Completados!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Puntos: \(score)")
                    .font(.title2.bold())
                    .foregroundColor(.yellow)

                if phase == .doubles {
                    Button("¡Avanzar a Casi Dobles! →") {
                        withAnimation(.spring()) {
                            phase = .nearDoubles
                            phaseComplete = false
                            buildCards()
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .orange.opacity(0.4), radius: 8)
                } else {
                    Button("¡Jugar de Nuevo!") {
                        withAnimation(.spring()) {
                            phase = .doubles
                            score = 0
                            phaseComplete = false
                            buildCards()
                        }
                    }
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
            }
            .padding(32)
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.9), Color.orange.opacity(0.9)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(28)
            .shadow(radius: 24)
            .padding(.horizontal, 24)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Logic

    func buildCards() {
        activeCardID = nil

        switch phase {
        case .doubles:
            // 1+1 through 9+9
            let bases = Array(1...9).shuffled()
            cards = bases.map { CircusCard(base: $0, delta: 0) }

        case .nearDoubles:
            // a+(a+1) for a in 1...8
            let bases = Array(1...8).shuffled()
            cards = bases.map { base in
                CircusCard(base: base, delta: Bool.random() ? 1 : -1 < 0 ? 1 : 1)
            }
            // Half with delta +1, half conceptually same but shown differently
            cards = Array(1...8).shuffled().map { base in
                CircusCard(base: base, delta: 1)
            }
        }
    }

    func handleCardTap(_ card: CircusCard) {
        guard !card.isSolved else { return }
        withAnimation(.spring(response: 0.4)) {
            if activeCardID == card.id {
                activeCardID = nil
            } else {
                activeCardID = card.id
                buildChoices(for: card)
                // Mark as flipped
                if let idx = cards.firstIndex(where: { $0.id == card.id }) {
                    cards[idx].isFlipped = true
                }
            }
        }
    }

    func buildChoices(for card: CircusCard) {
        let correct = card.answer
        var set = Set<Int>()
        set.insert(correct)
        var attempts = 0
        while set.count < 3 && attempts < 40 {
            attempts += 1
            let offset = Int.random(in: 1...4) * (Bool.random() ? 1 : -1)
            let candidate = correct + offset
            if candidate > 0 { set.insert(candidate) }
        }
        choices = Array(set).shuffled()
    }

    func handleAnswer(_ choice: Int, for card: CircusCard) {
        guard let idx = cards.firstIndex(where: { $0.id == card.id }) else { return }

        if choice == card.answer {
            withAnimation(.spring()) {
                cards[idx].isSolved = true
                activeCardID = nil
            }
            score += phase == .nearDoubles ? 15 : 10
            AudioServicesPlaySystemSound(1057)

            let solved = cards.filter(\.isSolved).count
            if solved == cards.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring()) { phaseComplete = true }
                }
            }
        } else {
            AudioServicesPlaySystemSound(1053)
            withAnimation(.spring(response: 0.1).repeatCount(4, autoreverses: true)) {
                wrongFlash = true
            }
            // Flip card back
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrongFlash = false
                withAnimation(.spring()) {
                    cards[idx].isFlipped = false
                    activeCardID = nil
                }
            }
        }
    }
}

// MARK: - Card Cell

private struct CardCell: View {
    let card: CircusCard
    let isActive: Bool

    @State private var flipDegrees: Double = 0

    var body: some View {
        ZStack {
            if card.isSolved {
                solvedFace
            } else if card.isFlipped || isActive {
                questionFace
            } else {
                coverFace
            }
        }
        .frame(height: 80)
        .cornerRadius(14)
        .shadow(
            color: isActive ? Color.red.opacity(0.4) : .black.opacity(0.10),
            radius: isActive ? 10 : 4,
            x: 0, y: isActive ? 4 : 2
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
        .animation(.spring(response: 0.3), value: card.isSolved)
        .animation(.spring(response: 0.3), value: card.isFlipped)
    }

    var coverFace: some View {
        ZStack {
            LinearGradient(
                colors: [Color.red, Color.red.opacity(0.75)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 2) {
                Text("🎪")
                    .font(.system(size: 24))
                Text("?")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    var questionFace: some View {
        ZStack {
            Color.yellow.opacity(0.9)
            VStack(spacing: 2) {
                Text(card.emoji)
                    .font(.system(size: 26))
                Text(card.equationDisplay)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange, lineWidth: 2)
        )
    }

    var solvedFace: some View {
        ZStack {
            Color.green.opacity(0.85)
            VStack(spacing: 2) {
                Text(card.emoji)
                    .font(.system(size: 22))
                Text("\(card.leftNum)+\(card.rightNum)=\(card.answer)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { CircoDeDoblesView() }
}
