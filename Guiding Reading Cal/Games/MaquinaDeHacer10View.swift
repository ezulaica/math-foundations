
//
//  MaquinaDeHacer10View.swift
//  Math Foundations — Juegos
//
//  TEKS 1.3 · Estrategia "Hacer 10"
//  La máquina muestra un número del 1–9; el estudiante ingresa el complemento para llegar a 10.
//

import SwiftUI
import AudioToolbox

// MARK: - Feedback State

private enum FeedbackState: Equatable {
    case none, correct, incorrect
}

// MARK: - Main View

struct MaquinaDeHacer10View: View {
    @State private var displayNumber: Int = 5
    @State private var inputDigit: Int? = nil
    @State private var feedback: FeedbackState = .none
    @State private var score: Int = 0
    @State private var streak: Int = 0
    @State private var spinning: Bool = false
    @State private var reelOffset: CGFloat = 0
    @State private var lights: Bool = false
    @State private var wrongShake: CGFloat = 0
    @State private var showStreakBonus: Bool = false
    @State private var totalCorrect: Int = 0

    private var correctAnswer: Int { 10 - displayNumber }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer(minLength: 20)

                    machineBody(in: geo)

                    feedbackBanner
                        .frame(height: 44)
                        .padding(.vertical, 8)

                    equation
                        .padding(.bottom, 12)

                    numberPad
                        .padding(.horizontal, 32)
                        .padding(.bottom, 28)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.08, blue: 0.22),
                         Color(red: 0.20, green: 0.10, blue: 0.35)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("La Máquina de Hacer 10")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { spinMachine() }
    }

    // MARK: Header

    var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TEKS 1.3 · Hacer 10")
                    .font(.caption)
                    .foregroundColor(.yellow.opacity(0.8))
                Text("¿Qué número falta para llegar a 10?")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            Spacer()
            // Streak
            if streak >= 2 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak)")
                        .font(.headline.bold())
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.18))
                .cornerRadius(8)
            }
            // Score
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(score)")
                    .font(.title3.bold())
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(10)
        }
        .padding(.vertical, 6)
    }

    // MARK: Machine Body

    func machineBody(in geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Neon sign
            Text("★ HACER 10 ★")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.yellow)
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.yellow.opacity(0.6), lineWidth: 1.5)
                )
                .padding(.bottom, 14)

            // Machine cabinet
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.55, green: 0.35, blue: 0.10),
                                     Color(red: 0.40, green: 0.25, blue: 0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 8)

                // Decorative border lights
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        lights ? Color.yellow : Color.yellow.opacity(0.3),
                        lineWidth: 3
                    )
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true), value: lights)

                VStack(spacing: 16) {
                    // Reel window
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black)
                            .frame(height: 120)

                        // Number display with spin animation
                        Text("\(displayNumber)")
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .shadow(color: .yellow.opacity(0.6), radius: 8)
                            .offset(y: reelOffset)
                            .opacity(spinning ? 0 : 1)

                        if spinning {
                            VStack(spacing: 4) {
                                ForEach(0..<3) { _ in
                                    Text("?")
                                        .font(.system(size: 36, weight: .black))
                                        .foregroundColor(.yellow.opacity(0.4))
                                }
                            }
                        }

                        // Overlay lines
                        VStack {
                            Spacer()
                            Divider().background(Color.yellow.opacity(0.25))
                                .frame(height: 1)
                            Spacer()
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Answer slot
                    HStack(spacing: 16) {
                        Text("+ □ = 10")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))

                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 64, height: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            feedback == .correct ? Color.green :
                                            feedback == .incorrect ? Color.red :
                                            Color.yellow.opacity(0.4),
                                            lineWidth: 2
                                        )
                                )

                            if let digit = inputDigit {
                                Text("\(digit)")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(
                                        feedback == .correct ? .green :
                                        feedback == .incorrect ? .red : .yellow
                                    )
                                    .offset(x: wrongShake)
                            } else {
                                Text("?")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.yellow.opacity(0.3))
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: min(geo.size.width - 48, 340))
        }
        .onAppear { lights = true }
    }

    // MARK: Feedback Banner

    var feedbackBanner: some View {
        Group {
            switch feedback {
            case .correct:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text(streak >= 3 ? "¡COMBO x\(streak)! +\(bonusPoints) pts" : "¡Correcto! \(displayNumber) + \(correctAnswer) = 10")
                        .fontWeight(.bold)
                }
                .foregroundColor(.green)
                .font(.headline)
                .transition(.scale.combined(with: .opacity))

            case .incorrect:
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Intenta de nuevo. \(displayNumber) + ? = 10")
                }
                .foregroundColor(.red)
                .font(.headline)
                .transition(.scale.combined(with: .opacity))

            case .none:
                Color.clear
            }
        }
        .animation(.spring(response: 0.3), value: feedback)
    }

    private var bonusPoints: Int {
        streak >= 5 ? 30 : streak >= 3 ? 20 : 10
    }

    // MARK: Equation Display

    var equation: some View {
        HStack(spacing: 0) {
            numberBox("\(displayNumber)", color: .orange)
            operatorLabel("+")
            answerBox
            operatorLabel("=")
            numberBox("10", color: .yellow)
        }
    }

    func numberBox(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundColor(color)
            .frame(width: 52, height: 52)
            .background(color.opacity(0.15))
            .cornerRadius(10)
    }

    func operatorLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white.opacity(0.6))
            .frame(width: 32)
    }

    var answerBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    feedback == .correct ? Color.green :
                    feedback == .incorrect ? Color.red :
                    Color.white.opacity(0.5),
                    lineWidth: 2.5
                )
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.05).cornerRadius(10))

            Text(inputDigit.map { "\($0)" } ?? "□")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(
                    feedback == .correct ? .green :
                    feedback == .incorrect ? .red :
                    inputDigit != nil ? .white : .white.opacity(0.3)
                )
                .offset(x: wrongShake)
        }
    }

    // MARK: Number Pad

    var numberPad: some View {
        VStack(spacing: 10) {
            // Row 1: 1-5
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { n in
                    padButton(n)
                }
            }
            // Row 2: 6-9 + DEL
            HStack(spacing: 10) {
                ForEach(6...9, id: \.self) { n in
                    padButton(n)
                }
                // Delete
                Button {
                    inputDigit = nil
                    feedback = .none
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(12)
                }
            }
        }
    }

    func padButton(_ n: Int) -> some View {
        Button {
            submitAnswer(n)
        } label: {
            Text("\(n)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.purple.opacity(0.7))
                .cornerRadius(12)
                .shadow(color: .purple.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .disabled(feedback != .none || spinning)
    }

    // MARK: - Logic

    func submitAnswer(_ n: Int) {
        inputDigit = n
        if n == correctAnswer {
            feedback = .correct
            streak += 1
            totalCorrect += 1
            score += streak >= 5 ? 30 : streak >= 3 ? 20 : 10
            AudioServicesPlaySystemSound(1057)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                spinMachine()
            }
        } else {
            feedback = .incorrect
            streak = 0
            AudioServicesPlaySystemSound(1053)
            withAnimation(.linear(duration: 0.06).repeatCount(6, autoreverses: true)) {
                wrongShake = -8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                wrongShake = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                inputDigit = nil
                feedback = .none
            }
        }
    }

    func spinMachine() {
        inputDigit = nil
        feedback = .none
        spinning = true
        withAnimation(.easeIn(duration: 0.15)) { reelOffset = -30 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            displayNumber = Int.random(in: 1...9)
            reelOffset = 30
            withAnimation(.spring(response: 0.3)) { reelOffset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                spinning = false
            }
        }
    }
}

#Preview {
    NavigationStack { MaquinaDeHacer10View() }
}
