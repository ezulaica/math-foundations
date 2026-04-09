
//
//  ImanDeNumerosView.swift
//  Math Foundations — Juegos
//
//  TEKS 1.3 · Suma y Resta: El Imán de Números
//  El estudiante arrastra parejas de números que sumen el número objetivo hacia el imán.
//  Refuerza familias de operaciones y números complementarios.
//

import SwiftUI
import AudioToolbox

// MARK: - Models

struct NumberTile: Identifiable {
    let id = UUID()
    var value: Int
    var isSnapped: Bool = false
    var color: Color
}

// MARK: - Main Game View

struct ImanDeNumerosView: View {
    @State private var targetNumber: Int = 10
    @State private var tiles: [NumberTile] = []
    @State private var score: Int = 0
    @State private var successPairs: [(Int, Int)] = []
    @State private var showCelebration: Bool = false
    @State private var magnetCenter: CGPoint = .zero
    @State private var levelComplete: Bool = false
    @State private var selectedTile: NumberTile? = nil

    private let tileColors: [Color] = [
        .blue, .orange, .purple, .pink, .teal, .indigo, .green, .red
    ]
    private let possibleTargets = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                VStack(spacing: 0) {
                    headerBar
                    Spacer()
                    magnetSection(in: geo)
                    Spacer()
                    tilesSection
                        .padding(.bottom, 28)
                }
                if showCelebration {
                    celebrationOverlay
                }
                if levelComplete {
                    levelCompleteOverlay
                }
            }
        }
        .navigationTitle("El Imán de Números")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { newGame() }
    }

    // MARK: Background

    var background: some View {
        LinearGradient(
            colors: [Color(red: 0.94, green: 0.96, blue: 1.0),
                     Color(red: 0.88, green: 0.92, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: Header

    var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TEKS 1.3 · Suma y Resta")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("¿Qué parejas suman \(targetNumber)?")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            Spacer()
            // Score badge
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(score)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.08), radius: 4)

            Button { withAnimation(.spring()) { newGame() } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .tint(.indigo)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Magnet Section

    func magnetSection(in geo: GeometryProxy) -> some View {
        ZStack(alignment: .center) {
            // Matched pairs shown above magnet
            VStack(spacing: 6) {
                ForEach(Array(successPairs.enumerated()), id: \.offset) { _, pair in
                    HStack(spacing: 8) {
                        smallTile(value: pair.0, color: .green)
                        Text("+")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                        smallTile(value: pair.1, color: .green)
                        Text("= \(targetNumber)")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .offset(y: -130)

            // Magnet + target number
            VStack(spacing: 8) {
                Image(systemName: "magnet.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, Color(white: 0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(-45))
                    .shadow(color: .red.opacity(0.25), radius: 6, x: 0, y: 3)

                Text("\(targetNumber)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .frame(width: 150, height: 150)
            .background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: .indigo.opacity(0.18), radius: 18, x: 0, y: 6)
            )
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: MagnetCenterKey.self,
                        value: proxy.frame(in: .global).center
                    )
                }
            )
            .onPreferenceChange(MagnetCenterKey.self) { center in
                magnetCenter = center
            }
        }
        .frame(height: 240)
        .animation(.spring(response: 0.4), value: successPairs.count)
    }

    // MARK: Tiles Section

    var tilesSection: some View {
        let visible = tiles.filter { !$0.isSnapped }

        return VStack(spacing: 12) {
            if visible.isEmpty && !tiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.green)
                    Text("¡Encontraste todas las parejas!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Text("Arrastra las parejas al imán")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                    spacing: 14
                ) {
                    ForEach(visible) { tile in
                        DraggableTile(
                            tile: tile,
                            targetNumber: targetNumber,
                            magnetCenter: magnetCenter,
                            isSelected: selectedTile?.id == tile.id,
                            onDrop: { dropped in
                                handleDrop(dropped)
                            },
                            onTap: { tapped in
                                handleTap(tapped)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Small Tile

    func smallTile(value: Int, color: Color) -> some View {
        Text("\(value)")
            .font(.caption.bold())
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(color)
            .cornerRadius(6)
    }

    // MARK: Celebration Overlay

    var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("🎉")
                    .font(.system(size: 72))
                if let last = successPairs.last {
                    Text("\(last.0) + \(last.1) = \(targetNumber)")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
                Text("¡Muy bien!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.9))
                Button("Continuar") {
                    withAnimation { showCelebration = false }
                }
                .font(.headline)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: .green.opacity(0.4), radius: 8)
            }
            .padding(32)
            .background(Color.indigo.opacity(0.92))
            .cornerRadius(28)
            .shadow(radius: 24)
            .padding(.horizontal, 32)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: Level Complete Overlay

    var levelCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("⭐️")
                    .font(.system(size: 80))
                Text("¡Nivel Completado!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                Text("Puntos: \(score)")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Button("Jugar de Nuevo") {
                    withAnimation(.spring()) {
                        levelComplete = false
                        newGame()
                    }
                }
                .font(.headline)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(16)
                .shadow(color: .yellow.opacity(0.4), radius: 8)
            }
            .padding(36)
            .background(
                LinearGradient(colors: [.indigo, .purple],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .cornerRadius(28)
            .shadow(radius: 28)
            .padding(.horizontal, 24)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Game Logic

    func newGame() {
        successPairs = []
        showCelebration = false
        levelComplete = false
        selectedTile = nil
        targetNumber = possibleTargets.randomElement()!
        tiles = buildTiles(for: targetNumber)
    }

    func buildTiles(for target: Int) -> [NumberTile] {
        var used = Set<Int>()
        var pairs: [(Int, Int)] = []

        // Generate 3 valid pairs
        while pairs.count < 3 {
            let a = Int.random(in: 1...(target - 1))
            let b = target - a
            guard a != b, !used.contains(a), !used.contains(b) else { continue }
            used.insert(a); used.insert(b)
            pairs.append((a, b))
        }

        var pool = pairs.flatMap { [$0.0, $0.1] }

        // Add 2 distractors
        var attempts = 0
        while pool.count < 8 && attempts < 50 {
            attempts += 1
            let d = Int.random(in: 1...(target - 1))
            guard !used.contains(d), !used.contains(target - d) else { continue }
            used.insert(d)
            pool.append(d)
        }

        pool.shuffle()
        return pool.enumerated().map { idx, value in
            NumberTile(value: value, color: tileColors[idx % tileColors.count])
        }
    }

    func handleDrop(_ tile: NumberTile) {
        // Find a visible complement
        let complement = targetNumber - tile.value
        guard complement > 0, complement != tile.value,
              let idxA = tiles.firstIndex(where: { $0.id == tile.id && !$0.isSnapped }),
              let idxB = tiles.firstIndex(where: {
                  $0.value == complement && !$0.isSnapped && $0.id != tile.id
              })
        else { return }

        tiles[idxA].isSnapped = true
        tiles[idxB].isSnapped = true
        successPairs.append((tile.value, complement))
        score += 10
        AudioServicesPlaySystemSound(1057)

        withAnimation(.spring()) { showCelebration = true }

        if tiles.allSatisfy({ $0.isSnapped }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showCelebration = false
                withAnimation(.spring()) { levelComplete = true }
            }
        }
    }

    func handleTap(_ tile: NumberTile) {
        guard !tile.isSnapped else { return }
        if let first = selectedTile {
            if first.id == tile.id {
                selectedTile = nil
                return
            }
            // Check if they form a pair
            if first.value + tile.value == targetNumber {
                var tapTile = tile
                tapTile.isSnapped = false
                handleDrop(first)
            } else {
                // Wrong pair — flash and deselect
                selectedTile = tile
            }
        } else {
            selectedTile = tile
        }
    }
}

// MARK: - Draggable Tile View

struct DraggableTile: View {
    let tile: NumberTile
    let targetNumber: Int
    let magnetCenter: CGPoint
    let isSelected: Bool
    let onDrop: (NumberTile) -> Void
    let onTap: (NumberTile) -> Void

    @State private var offset: CGSize = .zero
    @State private var dragging: Bool = false
    @State private var tileCenter: CGPoint = .zero

    var body: some View {
        Text("\(tile.value)")
            .font(.title2)
            .fontWeight(.black)
            .foregroundColor(.white)
            .frame(width: 62, height: 62)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(tile.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                    )
            )
            .shadow(
                color: dragging ? tile.color.opacity(0.55) : tile.color.opacity(0.28),
                radius: dragging ? 14 : 5,
                x: 0, y: dragging ? 8 : 2
            )
            .scaleEffect(dragging ? 1.18 : (isSelected ? 1.08 : 1.0))
            .offset(offset)
            .zIndex(dragging ? 10 : 1)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: TileCenterKey.self,
                        value: proxy.frame(in: .global).center
                    )
                }
            )
            .onPreferenceChange(TileCenterKey.self) { center in
                tileCenter = center
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { val in
                        dragging = true
                        offset = val.translation
                    }
                    .onEnded { val in
                        dragging = false
                        let dropped = CGPoint(
                            x: tileCenter.x + val.translation.width,
                            y: tileCenter.y + val.translation.height
                        )
                        let dist = hypot(dropped.x - magnetCenter.x,
                                         dropped.y - magnetCenter.y)
                        withAnimation(.spring(response: 0.35)) { offset = .zero }
                        if dist < 110 { onDrop(tile) }
                    }
            )
            .onTapGesture { onTap(tile) }
            .animation(.spring(response: 0.3), value: dragging)
            .animation(.spring(response: 0.2), value: isSelected)
    }
}

// MARK: - Preference Keys

private struct MagnetCenterKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

private struct TileCenterKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// MARK: - CGRect extension

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ImanDeNumerosView()
    }
}
