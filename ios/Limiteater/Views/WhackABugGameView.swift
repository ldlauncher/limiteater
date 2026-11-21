//
//  WhackABugGameView.swift
//  Limiteater
//  Arcade mini-game 4: Whack-a-Bug / Debugger - Stomp bugs before the server crashes!
//

import SwiftUI
import Combine

enum ServerSlotState: Equatable {
    case empty
    case bug(type: BugType)
    case squashed
}

enum BugType: String {
    case standardBug = "🐛"
    case rateLimit = "429"
    case glitch = "👾"
    case warning = "⚠️"
    case petFriendly = "🪲" // Friendly mascot, don't tap!
    
    var points: Int {
        switch self {
        case .standardBug: return 10
        case .rateLimit: return 25
        case .glitch: return 15
        case .warning: return 10
        case .petFriendly: return -15
        }
    }
}

public struct WhackABugGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tokens: Int
    @Binding var beetle: Beetle
    
    @State private var slots: [ServerSlotState] = Array(repeating: .empty, count: 9)
    @State private var score: Int = 0
    @State private var combo: Int = 0
    @State private var timeRemaining: Int = 30
    @State private var isPlaying: Bool = false
    @State private var isGameOver: Bool = false
    @State private var hitNotice: String = ""
    
    let gameTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let tickTimer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()
    
    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    public init(tokens: Binding<Int>, beetle: Binding<Beetle>) {
        self._tokens = tokens
        self._beetle = beetle
    }
    
    public var body: some View {
        ZStack {
            // Dark Server Matrix Background
            Color(red: 0.04, green: 0.05, blue: 0.09)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Top HUD
                HStack {
                    Button("Выход") {
                        tokens += score
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Time Left Pill
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(timeRemaining)с")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(timeRemaining <= 5 ? .red : .cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                    
                    Spacer()
                    
                    // Score
                    HStack(spacing: 4) {
                        Text("🪙")
                        Text("\(score)")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Title & Combo
                VStack(spacing: 2) {
                    Text("🔨 Дебаггер Серверов")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.orange)
                    
                    if combo > 1 {
                        Text("🔥 КОМБО x\(combo)! (+бонус токенов)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.yellow)
                    } else {
                        Text("Тапай по багам и 429 ошибкам! Не трогай Клодика!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 3x3 Server Rack Terminal Grid
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(0..<9, id: \.self) { index in
                        serverSlotView(at: index)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Notice text
                Text(hitNotice.isEmpty ? " " : hitNotice)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.yellow)
                    .frame(height: 24)
                
                Spacer()
            }
            
            // Start overlay
            if !isPlaying && !isGameOver {
                Color.black.opacity(0.85).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("🔨 ДЕБАГГЕР (WHACK-A-BUG)")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.orange)
                    
                    Text("Баги захватывают серверную стойку! Выбивай их пальцем за 30 секунд!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🐛 Баг = +10 токенов").foregroundColor(.green)
                        Text("429 Ошибка = +25 токенов!").foregroundColor(.yellow)
                        Text("🪲 Свой Клодик = -15 штраф!").foregroundColor(.red)
                    }
                    .font(.caption.weight(.bold))
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button("СТАРТ 🚀") {
                        startGame()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .padding(24)
            }
            
            // Game Over overlay
            if isGameOver {
                Color.black.opacity(0.85).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("⏰ ВРЕМЯ ВЫШЛО!")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.orange)
                    
                    Text("Дебаг завершён!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Ты нафармил: +\(score) токенов! 🪙")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.yellow)
                    
                    HStack(spacing: 16) {
                        Button("Забрать токены 🎁") {
                            tokens += score
                            beetle.tokensEaten += score * 10
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.headline.weight(.bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .cornerRadius(16)
                        
                        Button("Ещё раз 🔄") {
                            startGame()
                        }
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                }
                .padding(24)
            }
        }
        .onReceive(gameTimer) { _ in
            guard isPlaying && !isGameOver else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
        .onReceive(tickTimer) { _ in
            guard isPlaying && !isGameOver else { return }
            updateSlots()
        }
    }
    
    private func serverSlotView(at index: Int) -> some View {
        let state = slots[index]
        return Button(action: {
            slotTapped(at: index)
        }) {
            ZStack {
                // Server Chassis Cell
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.12, green: 0.14, blue: 0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1.5)
                    )
                
                // Status LED
                VStack {
                    HStack {
                        Circle()
                            .fill(state == .empty ? Color.gray.opacity(0.4) : Color.green)
                            .frame(width: 6, height: 6)
                        Spacer()
                    }
                    .padding(8)
                    Spacer()
                }
                
                // Contents
                switch state {
                case .empty:
                    Text("idle")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.4))
                case .bug(let type):
                    VStack(spacing: 2) {
                        Text(type.rawValue)
                            .font(.system(size: 34))
                        if type == .rateLimit {
                            Text("ERROR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                case .squashed:
                    Text("💥 FIXED!")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .frame(height: 95)
        }
    }
    
    private func startGame() {
        score = 0
        combo = 0
        timeRemaining = 30
        slots = Array(repeating: .empty, count: 9)
        isGameOver = false
        isPlaying = true
        hitNotice = ""
    }
    
    private func endGame() {
        isPlaying = false
        isGameOver = true
    }
    
    private func updateSlots() {
        // Randomly clear some squashed or old bugs
        for i in 0..<slots.count {
            if slots[i] == .squashed || Double.random(in: 0...1) < 0.3 {
                slots[i] = .empty
            }
        }
        
        // Spawn 1 to 2 new bugs in empty slots
        let emptyIndices = slots.indices.filter { slots[$0] == .empty }
        if let randomIdx = emptyIndices.randomElement() {
            let roll = Double.random(in: 0...1)
            let bugType: BugType
            if roll < 0.45 {
                bugType = .standardBug
            } else if roll < 0.70 {
                bugType = .rateLimit
            } else if roll < 0.85 {
                bugType = .warning
            } else {
                bugType = .petFriendly
            }
            slots[randomIdx] = .bug(type: bugType)
        }
    }
    
    private func slotTapped(at index: Int) {
        guard isPlaying && !isGameOver else { return }
        
        if case .bug(let type) = slots[index] {
            slots[index] = .squashed
            let pts = type.points
            if pts > 0 {
                combo += 1
                let totalPts = pts + (combo * 2)
                score += totalPts
                hitNotice = "+\(totalPts) 🪙 \(type.rawValue) ИСПРАВЛЕН!"
            } else {
                combo = 0
                score = max(0, score + pts)
                hitNotice = "Ай! Не бей Клодика! -15 💔"
            }
        } else {
            // Missed tap
            combo = 0
        }
    }
}
