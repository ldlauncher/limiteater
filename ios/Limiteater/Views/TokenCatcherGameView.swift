//
//  TokenCatcherGameView.swift
//  Limiteater
//  Arcade mini-game: Catch falling tokens and dodge 429 errors!
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
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var spawnCounter: Int = 0
    
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
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Счёт: \(score) 🪙")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Text(String(repeating: "❤️", count: max(0, lives)))
                }
                .padding()
                
                // Playfield
                GeometryReader { geo in
                    ZStack {
                        // Falling objects
                        ForEach(items) { item in
                            Text(item.symbol)
                                .font(.system(size: item.isBug ? 26 : 22))
                                .position(x: item.x, y: item.y)
                        }
                        
                        // Player Beetle Basket
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                            Text("🪲")
                                .font(.title)
                        }
                        .position(x: playerX, y: geo.size.height - 40)
                        .gesture(
                            DragGesture()
                                .onChanged { val in
                                    playerX = min(max(30, val.location.x), geo.size.width - 30)
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
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Button("Забрать токены") {
                        tokens += score
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .font(.headline)
                }
            }
        }
    }
    
    private func updateGame(in size: CGSize) {
        guard !isGameOver else { return }
        
        spawnCounter += 1
        if spawnCounter % 12 == 0 {
            let isBug = Double.random(in: 0...1) < 0.35
            let symbol = isBug ? (Bool.random() ? "429" : "🐛") : "🪙"
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
            items[i].y += 7.0
            
            // Collision with player
            let dist = hypot(items[i].x - playerX, items[i].y - (size.height - 40))
            if dist < 35 {
                if items[i].isBug {
                    lives -= 1
                    if lives <= 0 {
                        isGameOver = true
                    }
                } else {
                    score += 10
                }
                items.remove(at: i)
                continue
            }
            
            if items[i].y > size.height {
                items.remove(at: i)
            }
        }
    }
}
