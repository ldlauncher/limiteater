//
//  FlappyBugGameView.swift
//  Limiteater
//  Arcade mini-game 2: Flappy Bug - Escape from the data center!
//

import SwiftUI
import Combine

struct PipeObstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var gapY: CGFloat
    let gapHeight: CGFloat = 135
    let width: CGFloat = 52
    var passed: Bool = false
}

public struct FlappyBugGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tokens: Int
    @Binding var beetle: Beetle
    
    @State private var birdY: CGFloat = 250
    @State private var velocity: CGFloat = 0
    @State private var pipes: [PipeObstacle] = []
    @State private var score: Int = 0
    @State private var highScore: Int = 0
    @State private var isPlaying: Bool = false
    @State private var isGameOver: Bool = false
    @State private var wingsFlap: Bool = false
    
    let gravity: CGFloat = 0.55
    let jumpImpulse: CGFloat = -9.0
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    
    public init(tokens: Binding<Int>, beetle: Binding<Beetle>) {
        self._tokens = tokens
        self._beetle = beetle
    }
    
    public var body: some View {
        ZStack {
            // Cyberpunk Server Room Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.15),
                    Color(red: 0.02, green: 0.03, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack {
                    // Background Server Grid Lines
                    VStack(spacing: 40) {
                        ForEach(0..<15) { _ in
                            Rectangle()
                                .fill(Color.blue.opacity(0.08))
                                .frame(height: 1)
                        }
                    }
                    
                    // Pipes (Server Racks)
                    ForEach(pipes) { pipe in
                        // Top Pipe (Upper Server Rack)
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red: 0.15, green: 0.18, blue: 0.28), Color(red: 0.09, green: 0.11, blue: 0.18)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: pipe.width, height: max(0, pipe.gapY - pipe.gapHeight / 2))
                                .overlay(
                                    Rectangle().stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                )
                            // Server LEDs
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 4, height: 4)
                                Circle().fill(Color.blue).frame(width: 4, height: 4)
                                Circle().fill(Color.red).frame(width: 4, height: 4)
                            }
                            .padding(.bottom, 6)
                        }
                        .position(x: pipe.x, y: (pipe.gapY - pipe.gapHeight / 2) / 2)
                        
                        // Bottom Pipe (Lower Server Rack)
                        ZStack(alignment: .top) {
                            let bottomHeight = max(0, geo.size.height - (pipe.gapY + pipe.gapHeight / 2))
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(red: 0.15, green: 0.18, blue: 0.28), Color(red: 0.09, green: 0.11, blue: 0.18)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: pipe.width, height: bottomHeight)
                                .overlay(
                                    Rectangle().stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                )
                            // Server LEDs
                            HStack(spacing: 4) {
                                Circle().fill(Color.yellow).frame(width: 4, height: 4)
                                Circle().fill(Color.purple).frame(width: 4, height: 4)
                                Circle().fill(Color.green).frame(width: 4, height: 4)
                            }
                            .padding(.top, 6)
                        }
                        .position(x: pipe.x, y: geo.size.height - (max(0, geo.size.height - (pipe.gapY + pipe.gapHeight / 2))) / 2)
                    }
                    
                    // Beetle Mascot (Flappy Player)
                    HStack(spacing: 2) {
                        Text(wingsFlap ? "🪽" : "💨")
                            .font(.system(size: 16))
                            .offset(y: wingsFlap ? -3 : 2)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 0.98, green: 0.52, blue: 0.18))
                                .frame(width: 38, height: 28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            Text("< >")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                        }
                    }
                    .rotationEffect(.degrees(Double(min(max(velocity * 3.5, -30), 65))))
                    .position(x: 90, y: birdY)
                    
                    // Top HUD
                    VStack {
                        HStack {
                            Button("Выход") {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(10)
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Text("🪙")
                                Text("\(score)")
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    
                    // Start overlay
                    if !isPlaying && !isGameOver {
                        VStack(spacing: 12) {
                            Text("🪲 Flappy Bug")
                                .font(.title.weight(.bold))
                                .foregroundColor(.orange)
                            Text("Побег из серверной!")
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                            Text("Тапай по экрану, чтобы махать крыльями и облетать серверные стойки!")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: startGame) {
                                Text("СТАРТ 🚀")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(16)
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                        .background(Color(red: 0.1, green: 0.12, blue: 0.2).opacity(0.95))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange, lineWidth: 1.5))
                        .padding(.horizontal, 30)
                    }
                    
                    // Game Over overlay
                    if isGameOver {
                        VStack(spacing: 14) {
                            Text("💥 СЕРВЕР УПАЛ! (CRASH)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.red)
                            
                            Text("Заработано: +\(score) токенов! 🪙")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.yellow)
                            
                            HStack(spacing: 16) {
                                Button("Забрать") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.gray.opacity(0.4))
                                .cornerRadius(12)
                                
                                Button("Ещё раз 🔄") {
                                    startGame()
                                }
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.yellow)
                                .cornerRadius(12)
                            }
                        }
                        .padding(24)
                        .background(Color(red: 0.1, green: 0.12, blue: 0.2).opacity(0.95))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.red, lineWidth: 1.5))
                        .padding(.horizontal, 30)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    handleTap(in: geo.size)
                }
                .onReceive(timer) { _ in
                    updatePhysics(in: geo.size)
                }
            }
        }
    }
    
    private func startGame() {
        birdY = 250
        velocity = jumpImpulse
        pipes.removeAll()
        score = 0
        isGameOver = false
        isPlaying = true
    }
    
    private func handleTap(in size: CGSize) {
        guard !isGameOver else { return }
        if !isPlaying {
            startGame()
            return
        }
        velocity = jumpImpulse
        wingsFlap.toggle()
    }
    
    private func updatePhysics(in size: CGSize) {
        guard isPlaying && !isGameOver else { return }
        
        velocity += gravity
        birdY += velocity
        
        // Floor and ceiling collisions
        if birdY < 20 || birdY > size.height - 20 {
            gameOver()
            return
        }
        
        // Spawn pipes
        if pipes.isEmpty || (pipes.last?.x ?? 0) < size.width - 170 {
            let gapY = CGFloat.random(in: 120...(size.height - 150))
            pipes.append(PipeObstacle(x: size.width + 40, gapY: gapY))
        }
        
        // Move pipes
        for i in (0..<pipes.count).reversed() {
            pipes[i].x -= 3.2
            
            // Score tracking
            if !pipes[i].passed && pipes[i].x < 90 {
                pipes[i].passed = true
                score += 5
                tokens += 5
                beetle.tokensEaten += 50
            }
            
            // Check collision with bird
            let pipe = pipes[i]
            let birdLeft: CGFloat = 90 - 18
            let birdRight: CGFloat = 90 + 18
            let birdTop: CGFloat = birdY - 14
            let birdBottom: CGFloat = birdY + 14
            
            let pipeLeft = pipe.x - pipe.width / 2
            let pipeRight = pipe.x + pipe.width / 2
            let gapTop = pipe.gapY - pipe.gapHeight / 2
            let gapBottom = pipe.gapY + pipe.gapHeight / 2
            
            if birdRight > pipeLeft && birdLeft < pipeRight {
                if birdTop < gapTop || birdBottom > gapBottom {
                    gameOver()
                    return
                }
            }
            
            // Remove offscreen pipes
            if pipes[i].x < -50 {
                pipes.remove(at: i)
            }
        }
    }
    
    private func gameOver() {
        isGameOver = true
        isPlaying = false
    }
}
