
//
//  ConstructorDePuentesView.swift
//  Math Foundations — Juegos
//
//  TEKS 1.3 · Operaciones con números desconocidos (□ + 3 = 8)
//  El estudiante resuelve ecuaciones para colocar tablones sobre el río.
//  Tablón correcto → el puente avanza. Tablón incorrecto → cae al agua.
//

import SwiftUI
import AudioToolbox

// MARK: - Models

private enum UnknownPosition { case left, right }
private enum OperationType { case addition, subtraction }
private enum PlankState { case pending, placed, falling }

private struct BridgeEquation {
    let operationType: OperationType
    let unknownPosition: UnknownPosition
    let knownValue: Int     // the non-unknown operand
    let result: Int          // right-hand side of equation

    var answer: Int {
        switch (operationType, unknownPosition) {
        case (.addition, .left):  return result - knownValue   // □ + k = r → r - k
        case (.addition, .right): return result - knownValue   // k + □ = r → r - k
        case (.subtraction, .left):  return result + knownValue  // □ - k = r → r + k
        case (.subtraction, .right): return knownValue - result  // k - □ = r → k - r
        }
    }

    var displayString: String {
        let op = operationType == .addition ? "+" : "-"
        switch unknownPosition {
        case .left:  return "□ \(op) \(knownValue) = \(result)"
        case .right: return "\(knownValue) \(op) □ = \(result)"
        }
    }
}

private struct Plank: Identifiable {
    let id = UUID()
    var state: PlankState = .pending
    var xIndex: Int
}

// MARK: - Main View

struct ConstructorDePuentesView: View {
    // Bridge state
    @State private var planks: [Plank] = []
    @State private var currentEquation: BridgeEquation = .init(
        operationType: .addition, unknownPosition: .right,
        knownValue: 3, result: 8
    )
    @State private var inputAnswer: String = ""
    @State private var feedback: String = ""
    @State private var showFeedback: Bool = false
    @State private var feedbackCorrect: Bool = true
    @State private var score: Int = 0
    @State private var levelComplete: Bool = false
    @State private var splashOffset: CGFloat = 0
    @State private var showSplash: Bool = false
    @State private var currentPlankIdx: Int = 0
    @State private var wrongShake: CGFloat = 0

    private let totalPlanks = 7
    private let riverY: CGFloat = 260

    // Choices displayed as buttons (answer ± random offsets)
    @State private var choices: [Int] = []

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                skyAndRiver(width: geo.size.width)

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .zIndex(2)

                    Spacer(minLength: 0)

                    bridgeScene(width: geo.size.width)

                    Spacer(minLength: 0)

                    questionPanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                        .zIndex(2)
                }

                // Splash animation
                if showSplash {
                    Text("💧")
                        .font(.system(size: 36))
                        .offset(x: splashXForCurrentPlank(width: geo.size.width),
                                y: riverY + splashOffset)
                        .transition(.opacity)
                }

                // Level complete overlay
                if levelComplete {
                    levelCompleteOverlay
                }
            }
        }
        .navigationTitle("Constructor de Puentes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startGame() }
    }

    // MARK: Background

    func skyAndRiver(width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // Sky
            LinearGradient(
                colors: [Color(red: 0.53, green: 0.81, blue: 0.98),
                         Color(red: 0.70, green: 0.92, blue: 1.0)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Mountains / hills
            HillsShape()
                .fill(Color(red: 0.38, green: 0.72, blue: 0.40))
                .frame(height: 120)
                .offset(y: 140)

            // River
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.45, blue: 0.85),
                                 Color(red: 0.20, green: 0.55, blue: 0.95)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 90)
                .offset(y: riverY)
                .ignoresSafeArea(edges: .horizontal)

            // River shimmer
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.25))
                    .frame(width: CGFloat.random(in: 40...90), height: 6)
                    .offset(
                        x: CGFloat(i) * 80 - 120,
                        y: riverY + 20 + CGFloat(i % 2) * 22
                    )
            }

            // Ground (left bank)
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.12))
                .frame(width: 52, height: 100)
                .offset(x: -(UIScreen.main.bounds.width / 2 - 26), y: riverY + 20)

            // Ground (right bank)
            RoundedRectangle(cornerRadius: 0)
                .fill(Color(red: 0.45, green: 0.30, blue: 0.12))
                .frame(width: 52, height: 100)
                .offset(x: UIScreen.main.bounds.width / 2 - 26, y: riverY + 20)
        }
    }

    // MARK: Bridge Scene

    func bridgeScene(width: CGFloat) -> some View {
        ZStack {
            // Support posts
            ForEach(0..<totalPlanks, id: \.self) { i in
                let x = plankX(index: i, width: width)
                if i < currentPlankIdx {
                    Rectangle()
                        .fill(Color(red: 0.45, green: 0.28, blue: 0.08))
                        .frame(width: 8, height: 26)
                        .offset(x: x, y: riverY - 6)
                }
            }

            // Planks
            ForEach(planks) { plank in
                plankView(plank, width: width)
            }

            // Character (little person on bridge)
            if currentPlankIdx > 0 && !levelComplete {
                let charX = plankX(index: currentPlankIdx - 1, width: width)
                Text("🧒")
                    .font(.system(size: 28))
                    .offset(x: charX, y: riverY - 42)
                    .animation(.spring(response: 0.5), value: currentPlankIdx)
            }
        }
        .frame(height: 380)
    }

    @ViewBuilder
    func plankView(_ plank: Plank, width: CGFloat) -> some View {
        let x = plankX(index: plank.xIndex, width: width)
        let baseY = riverY - 18

        switch plank.state {
        case .placed:
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.60, green: 0.38, blue: 0.12))
                .frame(width: plankWidth(width: width) - 4, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(red: 0.80, green: 0.55, blue: 0.20), lineWidth: 1)
                )
                .offset(x: x, y: baseY)
                .transition(.move(edge: .top).combined(with: .opacity))

        case .falling:
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.60, green: 0.38, blue: 0.12).opacity(0.6))
                .frame(width: plankWidth(width: width) - 4, height: 18)
                .offset(x: x, y: baseY + 60)
                .rotationEffect(.degrees(30), anchor: .center)
                .opacity(0.3)
                .transition(.opacity)

        case .pending:
            EmptyView()
        }
    }

    func plankX(index: Int, width: CGFloat) -> CGFloat {
        let totalWidth = width - 104 // leave space for banks
        let step = totalWidth / CGFloat(totalPlanks)
        return -width / 2 + 52 + step * CGFloat(index) + step / 2
    }

    func plankWidth(width: CGFloat) -> CGFloat {
        (width - 104) / CGFloat(totalPlanks)
    }

    func splashXForCurrentPlank(width: CGFloat) -> CGFloat {
        let idx = max(0, currentPlankIdx - 1)
        return plankX(index: idx, width: width)
    }

    // MARK: Header

    var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TEKS 1.3 · Números Desconocidos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Resuelve para cruzar el río")
                    .font(.subheadline.bold())
            }
            Spacer()
            // Progress
            HStack(spacing: 4) {
                Image(systemName: "puzzlepiece.fill")
                    .foregroundColor(.brown)
                    .font(.caption)
                Text("\(currentPlankIdx)/\(totalPlanks)")
                    .font(.subheadline.bold())
                    .foregroundColor(.brown)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.brown.opacity(0.12))
            .cornerRadius(8)

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(score)")
                    .font(.title3.bold())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(8)
        }
        .padding(.vertical, 6)
        .background(Color(.systemBackground).opacity(0.85))
        .cornerRadius(12)
    }

    // MARK: Question Panel

    var questionPanel: some View {
        VStack(spacing: 14) {
            // Equation
            HStack {
                Image(systemName: "puzzlepiece.fill")
                    .foregroundColor(.brown)
                Text(currentEquation.displayString)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)

            // Feedback
            if showFeedback {
                HStack(spacing: 6) {
                    Image(systemName: feedbackCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(feedback)
                        .fontWeight(.semibold)
                }
                .foregroundColor(feedbackCorrect ? .green : .red)
                .font(.subheadline)
                .transition(.scale.combined(with: .opacity))
            }

            // Answer choices
            HStack(spacing: 12) {
                ForEach(choices, id: \.self) { choice in
                    choiceButton(choice)
                }
            }
        }
        .animation(.spring(response: 0.3), value: showFeedback)
        .padding(16)
        .background(Color(.systemBackground).opacity(0.92))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 4)
    }

    func choiceButton(_ value: Int) -> some View {
        Button {
            submitAnswer(value)
        } label: {
            Text("\(value)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .indigo.opacity(0.35), radius: 5, x: 0, y: 3)
                .offset(x: wrongShake)
        }
        .disabled(showFeedback)
    }

    // MARK: Level Complete

    var levelCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("🌉")
                    .font(.system(size: 72))
                Text("¡Puente Completo!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text("¡Cruzaste el río!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.85))
                Text("Puntos: \(score)")
                    .font(.title2.bold())
                    .foregroundColor(.yellow)
                Button("Jugar de Nuevo") {
                    withAnimation(.spring()) {
                        levelComplete = false
                        startGame()
                    }
                }
                .font(.headline)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.4), radius: 8)
            }
            .padding(36)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.35, blue: 0.70),
                             Color(red: 0.20, green: 0.55, blue: 0.85)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(28)
            .shadow(radius: 28)
            .padding(.horizontal, 24)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Logic

    func startGame() {
        planks = []
        currentPlankIdx = 0
        score = 0
        levelComplete = false
        feedback = ""
        showFeedback = false
        generateEquation()
    }

    func generateEquation() {
        var eq: BridgeEquation
        let difficulty = min(currentPlankIdx, 5)

        if difficulty < 3 {
            // Addition only, simple (sum ≤ 10)
            let result = Int.random(in: 4...10)
            let known = Int.random(in: 1...(result - 1))
            let side: UnknownPosition = Bool.random() ? .left : .right
            eq = BridgeEquation(operationType: .addition, unknownPosition: side,
                                knownValue: known, result: result)
        } else {
            // Mix addition + subtraction, larger numbers
            let opType: OperationType = Bool.random() ? .addition : .subtraction
            let result = Int.random(in: 3...15)

            if opType == .addition {
                let known = Int.random(in: 1...(result - 1))
                let side: UnknownPosition = Bool.random() ? .left : .right
                eq = BridgeEquation(operationType: .addition, unknownPosition: side,
                                    knownValue: known, result: result)
            } else {
                // k - □ = r or □ - k = r
                let known = Int.random(in: (result + 1)...(result + 8))
                let side: UnknownPosition = .right  // k - □ = r
                eq = BridgeEquation(operationType: .subtraction, unknownPosition: side,
                                    knownValue: known, result: result)
            }
        }

        // Guard against negative answers
        guard eq.answer > 0 else {
            generateEquation(); return
        }

        currentEquation = eq
        choices = makeChoices(correct: eq.answer)
        showFeedback = false
    }

    func makeChoices(correct: Int) -> [Int] {
        var set = Set<Int>()
        set.insert(correct)
        var attempts = 0
        while set.count < 3 && attempts < 30 {
            attempts += 1
            let offset = Int.random(in: 1...4) * (Bool.random() ? 1 : -1)
            let candidate = correct + offset
            if candidate > 0 && candidate != correct { set.insert(candidate) }
        }
        return Array(set).shuffled()
    }

    func submitAnswer(_ value: Int) {
        if value == currentEquation.answer {
            // Correct — place plank
            let plank = Plank(state: .placed, xIndex: currentPlankIdx)
            withAnimation(.spring(response: 0.4)) {
                planks.append(plank)
                currentPlankIdx += 1
            }
            score += 10
            showFeedback(text: "¡Correcto! ✓  \(currentEquation.displayString.replacingOccurrences(of: "□", with: "\(value)"))", correct: true)
            AudioServicesPlaySystemSound(1057)

            if currentPlankIdx >= totalPlanks {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.spring()) { levelComplete = true }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    generateEquation()
                }
            }
        } else {
            // Wrong — falling plank
            let fallingPlank = Plank(state: .falling, xIndex: currentPlankIdx)
            withAnimation(.easeIn(duration: 0.3)) {
                planks.append(fallingPlank)
            }
            withAnimation(.easeIn(duration: 0.5)) {
                showSplash = true
                splashOffset = 0
            }
            AudioServicesPlaySystemSound(1053)

            withAnimation(.linear(duration: 0.07).repeatCount(5, autoreverses: true)) {
                wrongShake = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                wrongShake = 0
            }

            showFeedback(text: "¡Intenta de nuevo! El tablón cayó al agua 💧", correct: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { planks.removeAll { $0.state == .falling } }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showSplash = false
                }
            }
        }
    }

    func showFeedback(text: String, correct: Bool) {
        feedback = text
        feedbackCorrect = correct
        withAnimation { showFeedback = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showFeedback = false }
        }
    }
}

// MARK: - Hills Shape

private struct HillsShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.35, y: rect.height * 0.3),
            control1: CGPoint(x: rect.width * 0.05, y: rect.height * 0.6),
            control2: CGPoint(x: rect.width * 0.15, y: rect.height * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.65, y: rect.height * 0.4),
            control1: CGPoint(x: rect.width * 0.50, y: rect.height * 0.55),
            control2: CGPoint(x: rect.width * 0.55, y: rect.height * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.15),
            control1: CGPoint(x: rect.width * 0.78, y: rect.height * 0.48),
            control2: CGPoint(x: rect.width * 0.90, y: rect.height * 0.08)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { ConstructorDePuentesView() }
}
