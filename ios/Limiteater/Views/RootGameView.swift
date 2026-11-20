//
//  RootGameView.swift
//  Limiteater
//  Talking Tom 5-Room Navigation (Кухня, Туалет, Ванна, Спальня, Фарм)
//

import SwiftUI
import Combine

public struct RootGameView: View {
    @State private var currentRoom: RoomType = .kitchen
    @State private var beetle: Beetle = SharedDataManager.shared.loadBeetle()
    @State private var tokens: Int = SharedDataManager.shared.loadTokens()
    @State private var speechText: String = "Дай токенов! Иначе закрою контекст! 😈"
    
    // Action states
    @State private var isChewing: Bool = false
    @State private var isPoked: Bool = false
    @State private var showMultiPetSheet: Bool = false
    @State private var showMinigame: Bool = false
    @State private var showViralSheet: Bool = false
    
    // Timer for needs decay
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        ZStack {
            // Room Background
            roomBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Top Bar: Pet Name + Level & Token Wallet
                topStatsHeader
                
                // 2. The 4 Talking Tom Need Meters
                needsMetersRow
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
                
                // 3. Speech Bubble
                speechBubbleView
                    .padding(.horizontal, 24)
                
                // 4. Central Animated Beetle
                BeetleCanvasView(beetle: beetle, isChewing: isChewing, isPoked: isPoked)
                    .padding(.vertical, 20)
                    .onTapGesture {
                        pokeBeetle()
                    }
                
                Spacer()
                
                // 5. Room Specific Action / Props Area
                roomPropsArea
                    .frame(height: 80)
                    .padding(.bottom, 10)
                
                // 6. Talking Tom 5-Tab Bar
                talkingTomTabBar
            }
        }
        .sheet(isPresented: $showMultiPetSheet) {
            MultiPetSheetView(currentBeetle: $beetle)
        }
        .sheet(isPresented: $showMinigame) {
            TokenCatcherGameView(tokens: $tokens, beetle: $beetle)
        }
        .sheet(isPresented: $showViralSheet) {
            ViralReceiptView(beetle: beetle)
        }
        .onReceive(timer) { _ in
            decayNeeds()
        }
    }
    
    // MARK: - Subviews
    
    private var topStatsHeader: some View {
        HStack {
            Button(action: { showMultiPetSheet = true }) {
                HStack(spacing: 6) {
                    Text("🪲")
                    Text(beetle.name)
                        .font(.headline)
                        .bold()
                    Text("(Lvl \(beetle.level))")
                        .font(.caption)
                        .opacity(0.7)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange, lineWidth: 1.5))
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Text("🪙")
                Text("\(tokens)")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow, lineWidth: 1.5))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var needsMetersRow: some View {
        HStack(spacing: 8) {
            needBar(title: "Сытость", val: beetle.hunger, color: .orange)
            needBar(title: "Кэш", val: beetle.toilet, color: .purple)
            needBar(title: "Линтер", val: beetle.clean, color: .green)
            needBar(title: "Энергия", val: beetle.energy, color: .cyan)
        }
    }
    
    private func needBar(title: String, val: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.gray)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.4))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(val / 100.0))
                }
            }
            .frame(height: 7)
        }
    }
    
    private var speechBubbleView: some View {
        Text(speechText)
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.orange, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
    
    // MARK: - Room Props
    
    @ViewBuilder
    private var roomPropsArea: some View {
        switch currentRoom {
        case .kitchen:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FoodItem.catalog) { item in
                        Button(action: { feedFood(item) }) {
                            VStack(spacing: 4) {
                                Text(item.icon).font(.title2)
                                Text(item.name).font(.system(size: 11, weight: .bold))
                                Text("🪙 \(item.cost)").font(.system(size: 10, weight: .heavy)).foregroundColor(.yellow)
                            }
                            .frame(width: 80, height: 70)
                            .background(Color(red: 0.15, green: 0.17, blue: 0.25))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
            }
            
        case .toilet:
            Button(action: flushCache) {
                Label("Смыть кэш (rm -rf node_modules)", systemImage: "trash.fill")
                    .font(.subheadline)
                    .bold()
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            
        case .bath:
            Button(action: washLinter) {
                Label("Запустить линтер и пену", systemImage: "sparkles")
                    .font(.subheadline)
                    .bold()
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(20)
            }
            
        case .bedroom:
            Button(action: toggleSleep) {
                Label(beetle.isSleeping ? "☀️ Разбудить (Доброе утро!)" : "🌙 Уложить спать (Выкл. сервер)",
                      systemImage: beetle.isSleeping ? "sun.max.fill" : "moon.fill")
                    .font(.subheadline)
                    .bold()
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            
        case .arcade:
            HStack(spacing: 12) {
                Button(action: { showMinigame = true }) {
                    Label("Ловец токенов", systemImage: "gamecontroller.fill")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                }
                
                Button(action: { showViralSheet = true }) {
                    Label("Чек от ИИ", systemImage: "doc.text.fill")
                        .font(.caption)
                        .bold()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Talking Tom Bottom Tab Bar
    
    private var talkingTomTabBar: some View {
        HStack {
            ForEach(RoomType.allCases) { room in
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        currentRoom = room
                        speechText = beetle.randomQuote
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: room.icon)
                            .font(.system(size: 22))
                        Text(room.rawValue)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(currentRoom == room ? .orange : .gray)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(currentRoom == room ? Color.orange.opacity(0.15) : Color.clear)
                    .cornerRadius(14)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
        .background(Color(red: 0.07, green: 0.08, blue: 0.12).ignoresSafeArea(edges: .bottom))
    }
    
    private var roomBackgroundColor: Color {
        if beetle.isSleeping && currentRoom == .bedroom {
            return Color.black
        }
        switch currentRoom {
        case .kitchen: return Color(red: 0.14, green: 0.11, blue: 0.11)
        case .toilet: return Color(red: 0.08, green: 0.13, blue: 0.16)
        case .bath: return Color(red: 0.08, green: 0.15, blue: 0.17)
        case .bedroom: return Color(red: 0.09, green: 0.10, blue: 0.20)
        case .arcade: return Color(red: 0.17, green: 0.08, blue: 0.20)
        }
    }
    
    // MARK: - Actions
    
    private func feedFood(_ item: FoodItem) {
        guard tokens >= item.cost else {
            speechText = "Нет токенов! Иди фарми в мини-игре! 🪙"
            return
        }
        tokens -= item.cost
        beetle.hunger = min(100, beetle.hunger + item.hungerGain)
        beetle.tokensEaten += item.cost * 100
        isChewing = true
        speechText = "Ммм! \(item.name) сожран! Токены усвоены! 🤤"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isChewing = false
        }
        persistState()
    }
    
    private func flushCache() {
        beetle.toilet = 100
        speechText = "Кэш очищен! Все дампы памяти сброшены! 🚀"
        persistState()
    }
    
    private func washLinter() {
        beetle.clean = 100
        speechText = "Никаких синтаксических ошибок! Код блестит! ✨"
        persistState()
    }
    
    private func toggleSleep() {
        beetle.isSleeping.toggle()
        if beetle.isSleeping {
            speechText = "Zzz... Сервер спит. Лимиты восстанавливаются... 🌙"
        } else {
            beetle.energy = 100
            tokens += 50
            speechText = "Доброе утро! Держи утренний бонус +50 токенов! ☀️"
        }
        persistState()
    }
    
    private func pokeBeetle() {
        isPoked = true
        speechText = [
            "Эй, не тыкай без токенов!",
            "Щекотно! Мои жвалы чувствительны!",
            "Вайбкодим? Погнали!",
            "Тык! Минус 5 токенов за прикосновение!"
        ].randomElement()!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isPoked = false
        }
    }
    
    private func decayNeeds() {
        if beetle.isSleeping {
            beetle.energy = min(100, beetle.energy + 4)
        } else {
            beetle.hunger = max(0, beetle.hunger - 1)
            beetle.toilet = max(0, beetle.toilet - 1)
            beetle.clean = max(0, beetle.clean - 1)
            beetle.energy = max(0, beetle.energy - 1)
        }
        persistState()
    }
    
    private func persistState() {
        SharedDataManager.shared.saveBeetle(beetle)
        SharedDataManager.shared.saveTokens(tokens)
    }
}
