//
//  TokenCatcherGameView.swift
//  Limiteater
//  Arcade mini-game 1: Catch falling tokens and dodge 429 errors!
//  Hardware-accelerated Canvas for 60 FPS on iPhone 6s (Apple A9).
//

import SwiftUI
import Combine

struct FallingGameItem: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var isBug: Bool
    var symbol: String
}

public struct TokenCatcherGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tokens: Int
    @Binding var beetle: Beetle
    
    @State private var playerX: CGFloat = 180
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var isGameOver: Bool = false
    @State private var items: [FallingGameItem] = []
    @State private var spawnCounter: Int = 0
    
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()
    
    public init(tokens: Binding<Int>, beetle: Binding<Beetle>) {
        self._tokens = tokens
        self._beetle = beetle
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.1).ignoresSafeArea()
            
            VStack {
                // Header
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
                    
                    Text("Счёт: \(score) 🪙")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Text(String(repeating: "❤️", count: max(0, lives)))
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Hardware-Accelerated 60 FPS Canvas Playfield
                GeometryReader { geo in
                    ZStack {
                        Canvas { context, size in
                            // Render falling tokens and bugs
                            for item in items {
                                let resolved = context.resolve(
                                    Text(item.symbol)
                                        .font(.system(size: item.isBug ? 26 : 22))
                                )
                                context.draw(resolved, at: CGPoint(x: item.x, y: item.y))
                            }
                        }
                        
                        // Player Beetle Basket
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 54, height: 54)
                                .shadow(color: .orange.opacity(0.5), radius: 6)
                            Text("🪲")
                                .font(.system(size: 28))
                        }
                        .position(x: playerX, y: geo.size.height - 40)
                        .gesture(
                            DragGesture()
                                .onChanged { val in
                                    playerX = min(max(35, val.location.x), geo.size.width - 35)
                                }
                        )
                    }
                    .onReceive(timer) { _ in
                        updateGame(in: geo.size)
                    }
                }
            }
            
            if isGameOver {
                Color.black.opacity(0.85).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("ИГРА ОКОНЧЕНА!")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.red)
                    Text("Ты наловил: +\(score) токенов! 🪙")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.yellow)
                    Button("Забрать токены 🎁") {
                        tokens += score
                        beetle.tokensEaten += score * 10
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .font(.headline.weight(.bold))
                }
            }
        }
    }
    
    private func updateGame(in size: CGSize) {
        guard !isGameOver else { return }
        
        spawnCounter += 1
        if spawnCounter % 10 == 0 {
            let isBug = Double.random(in: 0...1) < 0.35
            let symbol = isBug ? (Bool.random() ? "429" : "🐛") : (Double.random(in: 0...1) < 0.2 ? "💎" : "🪙")
            let newItem = FallingGameItem(
                x: CGFloat.random(in: 40...(size.width - 40)),
                y: 0,
                isBug: isBug,
                symbol: symbol
            )
            items.append(newItem)
        }
        
        // Move & Collide
        for i in (0..<items.count).reversed() {
            items[i].y += 6.5
            
            // Collision with player
            let dist = hypot(items[i].x - playerX, items[i].y - (size.height - 40))
            if dist < 38 {
                if items[i].isBug {
                    lives -= 1
                    if lives <= 0 {
                        isGameOver = true
                    }
                } else {
                    let pts = items[i].symbol == "💎" ? 25 : 10
                    score += pts
                }
                items.remove(at: i)
                continue
            }
            
            if items[i].y > size.height + 20 {
                items.remove(at: i)
            }
        }
    }
}
