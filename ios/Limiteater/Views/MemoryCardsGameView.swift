//
//  MemoryCardsGameView.swift
//  Limiteater
//  Arcade mini-game 3: AI Memory Cards - Match pairs of IT tokens & AI models!
//

import SwiftUI
import Combine

struct MemoryCard: Identifiable {
    let id: Int
    let icon: String
    let name: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

public struct MemoryCardsGameView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tokens: Int
    @Binding var beetle: Beetle
    
    @State private var cards: [MemoryCard] = []
    @State private var firstSelectedIndex: Int? = nil
    @State private var secondSelectedIndex: Int? = nil
    @State private var score: Int = 0
    @State private var moves: Int = 0
    @State private var matchedPairs: Int = 0
    @State private var isWon: Bool = false
    @State private var isBusy: Bool = false
    
    private let cardTemplates: [(icon: String, name: String)] = [
        ("🤖", "Claude"),
        ("🧠", "GPT-4"),
        ("⚡", "Cursor"),
        ("🐛", "Bug"),
        ("🛑", "429 Limit"),
        ("🪙", "Token")
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    public init(tokens: Binding<Int>, beetle: Binding<Beetle>) {
        self._tokens = tokens
        self._beetle = beetle
    }
    
    public var body: some View {
        ZStack {
            // Cyberpunk Dark Background
            Color(red: 0.06, green: 0.08, blue: 0.14)
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                // Top Header
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
                    
                    Text("Ходы: \(moves)")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("🪙")
                        Text("\(score)")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Text("🃏 Нейро-Память")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.orange)
                
                Text("Найди одинаковые пары токенов и моделей!")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // 4x3 Cards Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        cardView(for: index)
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Restart button
                Button(action: setupGame) {
                    Label("Перемешать заново 🔄", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(14)
                }
                .padding(.bottom, 12)
            }
            
            // Victory Dialog
            if isWon {
                Color.black.opacity(0.85).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("🎉 ПОЛНЫЙ МЭТЧ!")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.green)
                    
                    Text("Все пары найдены за \(moves) ходов!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Награда: +\(score + 50) токенов! 🪙")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.yellow)
                    
                    Button("Забрать награду 🎁") {
                        tokens += 50
                        beetle.tokensEaten += 500
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .cornerRadius(16)
                }
                .padding(24)
            }
        }
        .onAppear {
            setupGame()
        }
    }
    
    private func cardView(for index: Int) -> some View {
        let card = cards[index]
        return Button(action: {
            cardTapped(at: index)
        }) {
            ZStack {
                if card.isFaceUp || card.isMatched {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(card.isMatched ? Color.green.opacity(0.25) : Color(red: 0.16, green: 0.20, blue: 0.32))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(card.isMatched ? Color.green : Color.cyan, lineWidth: 2)
                        )
                    VStack(spacing: 4) {
                        Text(card.icon)
                            .font(.system(size: 32))
                        Text(card.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.red.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                    Text("🪲")
                        .font(.title2)
                }
            }
            .frame(height: 90)
        }
        .disabled(card.isFaceUp || card.isMatched || isBusy)
    }
    
    private func setupGame() {
        var newCards: [MemoryCard] = []
        var idCounter = 0
        
        for template in cardTemplates {
            newCards.append(MemoryCard(id: idCounter, icon: template.icon, name: template.name))
            idCounter += 1
            newCards.append(MemoryCard(id: idCounter, icon: template.icon, name: template.name))
            idCounter += 1
        }
        
        cards = newCards.shuffled()
        firstSelectedIndex = nil
        secondSelectedIndex = nil
        score = 0
        moves = 0
        matchedPairs = 0
        isWon = false
        isBusy = false
    }
    
    private func cardTapped(at index: Int) {
        guard !cards[index].isFaceUp && !cards[index].isMatched && !isBusy else { return }
        
        cards[index].isFaceUp = true
        
        if firstSelectedIndex == nil {
            firstSelectedIndex = index
        } else if secondSelectedIndex == nil {
            secondSelectedIndex = index
            moves += 1
            checkForMatch()
        }
    }
    
    private func checkForMatch() {
        guard let first = firstSelectedIndex, let second = secondSelectedIndex else { return }
        
        if cards[first].name == cards[second].name {
            // Match!
            cards[first].isMatched = true
            cards[second].isMatched = true
            score += 15
            tokens += 15
            matchedPairs += 1
            
            firstSelectedIndex = nil
            secondSelectedIndex = nil
            
            if matchedPairs == cardTemplates.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isWon = true
                }
            }
        } else {
            // Mismatch
            isBusy = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                cards[first].isFaceUp = false
                cards[second].isFaceUp = false
                firstSelectedIndex = nil
                secondSelectedIndex = nil
                isBusy = false
            }
        }
    }
}
