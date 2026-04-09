
//
//  RuedaDeFamiliasView.swift
//  Math Foundations — Juegos
//
//  TEKS 1.3 · Familias de Operaciones
//  La rueda muestra 3 números; el estudiante completa las 4 ecuaciones de la familia.
//  Refuerza la relación inversa entre suma y resta.
//

import SwiftUI
import AudioToolbox

// MARK: - Fact Family Model

private struct FactFamily {
    let a: Int   // first addend
    let b: Int   // second addend
    var c: Int { a + b }  // sum

    // 4 equations: index → (left, op, right, answer)
    var equations: [(left: String, op: String, right: String, answer: Int)] {
        [
            ("\(a)", "+", "\(b)", c),   // a + b = ?
            ("\(b)", "+", "\(a)", c),   // b + a = ?
            ("\(c)", "-", "\(a)", b),   // c - a = ?
            ("\(c)", "-", "\(b)", a)    // c - b = ?
        ]
    }

    static func random(maxSum: Int = 15) -> FactFamily {
        let a = Int.random(in: 1...min(maxSum - 1, 9))
        let b = Int.random(in: 1...min(maxSum - a, 9))
        return FactFamily(a: a, b: b)
    }
}

// MARK: - Main View

struct RuedaDeFamiliasView: View {
    @State private var family: FactFamily = .random()
    @State private var currentEquation: Int = 0          // 0…3
    @State private var choices: [Int] = []
    @State private var statuses: [Bool?] = [nil, nil, nil, nil]  // per equation
    @State private var wheelDegrees: Double = 0
    @State private var score: Int = 0
    @State private var familyComplete: Bool = false
    @State private var wrongShake: Bool = false
    @State private var choiceCorrect: Int? = nil

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 8)

                    wheelSection
                        .padding(.top, 16)

                    progressDots
                        .padding(.top, 14)

                    equationDisplay
                        .padding(.top, 18)
                        .padding(.horizontal, 24)

                    choicesGrid
                        .padding(.top, 18)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.97, blue: 0.88),
                         Color(red: 0.98, green: 0.93, blue: 0.75)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("La Rueda de Familias")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { generateChoices() }
        .overlay {
            if familyComplete {
                completionOverlay
            }
        }
    }

    // MARK: Header

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("TEKS 1.3 · Familias de Operaciones")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Completa las 4 ecuaciones de la familia")
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

    // MARK: Wheel

    var wheelSection: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.orange.opacity(0.35), lineWidth: 10)
                .frame(width: 210, height: 210)

            // Wheel background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.25), Color.yellow.opacity(0.15)],
                        center: .center, startRadius: 10, endRadius: 105
                    )
                )
                .frame(width: 200, height: 200)
                .shadow(color: .orange.opacity(0.2), radius: 12)

            // Spoke lines
            ForEach(0..<3) { i in
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 2, height: 90)
                    .offset(y: -45)
                    .rotationEffect(.degrees(Double(i) * 120))
            }

            // Number badges on wheel
            wheelNumber(family.c, angle: -90)   // top (sum)
            wheelNumber(family.a, angle: 30)     // bottom-right
            wheelNumber(family.b, angle: 150)    // bottom-left

            // Center hub
            Circle()
                .fill(Color.orange)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: .orange.opacity(0.4), radius: 4)
        }
        .rotationEffect(.degrees(wheelDegrees))
        .animation(.spring(response: 0.7, dampingFraction: 0.6), value: wheelDegrees)
    }

    func wheelNumber(_ n: Int, angle: Double) -> some View {
        let rad = Double.pi * angle / 180
        let r: Double = 72
        return Text("\(n)")
            .font(.system(size: 26, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 48, height: 48)
            .background(
                Circle()
                    .fill(n == family.c ? Color.red : Color.orange)
                    .shadow(color: .black.opacity(0.2), radius: 4)
            )
            .offset(x: CGFloat(cos(rad) * r), y: CGFloat(sin(rad) * r))
    }

    // MARK: Progress Dots

    var progressDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<4) { i in
                Circle()
                    .fill(
                        statuses[i] == true ? Color.green :
                        statuses[i] == false ? Color.red :
                        i == currentEquation ? Color.orange : Color.gray.opacity(0.3)
                    )
                    .frame(width: 12, height: 12)
                    .scaleEffect(i == currentEquation ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3), value: currentEquation)
            }
        }
    }

    // MARK: Equation Display

    var equationDisplay: some View {
        let eq = family.equations[currentEquation]

        return VStack(spacing: 8) {
            Text("Ecuación \(currentEquation + 1) de 4")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                // Left side
                equationToken(eq.left, highlighted: false)
                operatorToken(eq.op)
                equationToken(eq.right, highlighted: false)
                operatorToken("=")

                // Answer blank
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            choiceCorrect != nil ?
                                (choiceCorrect == eq.answer ? Color.green : Color.red) :
                                Color.orange,
                            lineWidth: 3
                        )
                        .frame(width: 60, height: 60)
                        .background(Color.white.cornerRadius(12))
                        .shadow(color: .orange.opacity(0.15), radius: 4)

                    if let chosen = choiceCorrect {
                        Text("\(chosen)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(chosen == eq.answer ? .green : .red)
                            .offset(x: wrongShake ? -6 : 0)
                    } else {
                        Text("?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.orange.opacity(0.5))
                    }
                }
                .modifier(ShakeModifier(active: wrongShake))
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.9))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    func equationToken(_ text: String, highlighted: Bool) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundColor(highlighted ? .orange : .primary)
            .frame(width: 52, height: 52)
    }

    func operatorToken(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.secondary)
            .frame(width: 28)
    }

    // MARK: Choices Grid

    var choicesGrid: some View {
        HStack(spacing: 14) {
            ForEach(choices, id: \.self) { choice in
                Button {
                    handleChoice(choice)
                } label: {
                    Text("\(choice)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .indigo.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .disabled(choiceCorrect != nil)
                .scaleEffect(choiceCorrect == choice ? 1.08 : 1.0)
                .animation(.spring(response: 0.2), value: choiceCorrect)
            }
        }
    }

    // MARK: Completion Overlay

    var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 72))
                Text("¡Familia Completa!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                // Show all 4 equations
                VStack(spacing: 6) {
                    ForEach(0..<4) { i in
                        let eq = family.equations[i]
                        Text("\(eq.left) \(eq.op) \(eq.right) = \(eq.answer)")
                            .font(.title3.bold())
                            .foregroundColor(.yellow)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.15))
                .cornerRadius(14)

                Button("Nueva Familia") {
                    withAnimation(.spring()) {
                        nextFamily()
                    }
                }
                .font(.headline)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: .orange.opacity(0.4), radius: 8)
            }
            .padding(30)
            .background(
                LinearGradient(
                    colors: [Color.indigo, Color.purple],
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

    func generateChoices() {
        let correct = family.equations[currentEquation].answer
        var set = Set<Int>()
        set.insert(correct)
        var attempts = 0
        while set.count < 3 && attempts < 40 {
            attempts += 1
            let offset = Int.random(in: 1...5) * (Bool.random() ? 1 : -1)
            let candidate = correct + offset
            if candidate > 0 { set.insert(candidate) }
        }
        choices = Array(set).shuffled()
        choiceCorrect = nil
    }

    func handleChoice(_ choice: Int) {
        let correct = family.equations[currentEquation].answer
        choiceCorrect = choice

        if choice == correct {
            statuses[currentEquation] = true
            score += 10
            AudioServicesPlaySystemSound(1057)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                if currentEquation < 3 {
                    currentEquation += 1
                    generateChoices()
                } else {
                    withAnimation(.spring()) { familyComplete = true }
                }
            }
        } else {
            statuses[currentEquation] = false
            AudioServicesPlaySystemSound(1053)
            withAnimation(.spring(response: 0.1).repeatCount(4, autoreverses: true)) {
                wrongShake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                wrongShake = false
                choiceCorrect = nil
                statuses[currentEquation] = nil
            }
        }
    }

    func nextFamily() {
        familyComplete = false
        family = .random()
        statuses = [nil, nil, nil, nil]
        currentEquation = 0
        withAnimation { wheelDegrees += 360 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generateChoices()
        }
    }
}

// MARK: - Shake Modifier

private struct ShakeModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content.offset(x: active ? -5 : 0)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { RuedaDeFamiliasView() }
}
