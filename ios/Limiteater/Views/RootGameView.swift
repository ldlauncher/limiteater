//
//  RootGameView.swift
//  Limiteater
//  Interactive My Talking Tom style gameplay for iOS 15+
//

import SwiftUI
import Combine

public struct RootGameView: View {
    @State private var currentRoom: RoomType = .kitchen
    @State private var beetle: Beetle = SharedDataManager.shared.loadBeetle()
    @State private var tokens: Int = SharedDataManager.shared.loadTokens()
    @State private var speechText: String = "Дай токенов! Иначе закрою контекст! 😈"
    
    // Interactive Bath Tools
    @State private var activeBathTool: String? = nil // "soap" or "shower"
    @State private var soapPosition: CGPoint = CGPoint(x: 80, y: 350)
    @State private var showerPosition: CGPoint = CGPoint(x: 300, y: 350)
    @State private var foamAmount: Double = 0.0
    @State private var isWaterFlowing: Bool = false
    
    // Interactive Feeding Drag State
    @State private var draggedFood: FoodItem? = nil
    @State private var foodDragOffset: CGSize = .zero
    
    // Interactive Petting & Poking
    @State private var eyeExpression: EyeExpression = .standard
    @State private var isPoked: Bool = false
    @State private var isChewing: Bool = false
    @State private var legWalkOffset: CGFloat = 0.0
    @State private var floatingHearts: [UUID] = []
    
    // Weather & Time
    @State private var currentWeather: WeatherType = .sunny
    @State private var emotionState: BeetleEmotionState = BeetleEmotionState.compute(for: Beetle(name: "Клодик"))
    
    // Modals
    @State private var showMultiPetSheet: Bool = false
    @State private var showMinigame: Bool = false
    @State private var showViralSheet: Bool = false
    
    let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        ZStack {
            // Room Background
            roomBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Status Header (Pet info, Weather, Time, Tokens)
                topHeaderView
                
                // 4 Need Meters (Hunger, Toilet, Clean, Energy)
                needsMetersRow
                    .padding(.horizontal)
                    .padding(.top, 6)
                
                Spacer()
                
                // Speech Bubble with Sarcastic AI Quote
                speechBubbleView
                    .padding(.horizontal, 24)
                
                // Central Interactive Mascot Stage
                ZStack {
                    // Beetle Mascot (Exact Claude 3D Block Mascot)
                    BeetleCanvasView(
                        beetle: beetle,
                        expression: eyeExpression,
                        foamAmount: foamAmount,
                        isChewing: isChewing,
                        isPoked: isPoked,
                        legWalkOffset: legWalkOffset
                    )
                    .gesture(
                        // Petting gesture (rubbing across beetle)
                        DragGesture()
                            .onChanged { _ in
                                handlePetting()
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    eyeExpression = .standard
                                }
                            }
                    )
                    .onTapGesture {
                        handlePoke()
                    }
                    
                    // Floating Love Hearts
                    ForEach(floatingHearts, id: \.self) { _ in
                        Text("💖")
                            .font(.title)
                            .offset(y: -70)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Running shower water stream
                    if isWaterFlowing {
                        waterStreamEffect
                    }
                }
                .frame(height: 220)
                
                Spacer()
                
                // Interactive Room Props (Soap/Shower, Food Tray, Toilet Lever)
                roomInteractiveArea
                    .frame(height: 110)
                    .padding(.bottom, 6)
                
                // Talking Tom 5-Tab Bar
                bottomTabBar
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
        .onAppear {
            updateEmotion()
        }
    }
    
    // MARK: - Header
    private var topHeaderView: some View {
        HStack {
            Button(action: { showMultiPetSheet = true }) {
                HStack(spacing: 6) {
                    Text("🪲")
                    Text(beetle.name)
                        .font(.headline.weight(.bold))
                    Text("(Lvl \(beetle.level))")
                        .font(.caption)
                        .opacity(0.7)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange, lineWidth: 1.2))
            }
            
            // Weather & Time Pill
            HStack(spacing: 4) {
                Image(systemName: emotionState.weather.icon)
                    .font(.caption2)
                Text(emotionState.timeOfDay.rawValue)
                    .font(.caption2.weight(.bold))
            }
            .foregroundColor(.cyan)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.cyan.opacity(0.15))
            .cornerRadius(12)
            
            Spacer()
            
            // Token Wallet
            HStack(spacing: 5) {
                Text("🪙")
                Text("\(tokens)")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.yellow.opacity(0.15))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow, lineWidth: 1.2))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Need Meters
    private var needsMetersRow: some View {
        HStack(spacing: 8) {
            needBar(title: "Сытость", val: beetle.hunger, color: .orange)
            needBar(title: "Кэш", val: beetle.toilet, color: .purple)
            needBar(title: "Линтер", val: beetle.clean, color: .green)
            needBar(title: "Энергия", val: beetle.energy, color: .cyan)
        }
    }
    
    private func needBar(title: String, val: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.4))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(val / 100.0))
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - Speech Bubble
    private var speechBubbleView: some View {
        Text(speechText)
            .font(.subheadline.weight(.bold))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange, lineWidth: 2))
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }
    
    // MARK: - Interactive Room Props
    @ViewBuilder
    private var roomInteractiveArea: some View {
        switch currentRoom {
        case .kitchen:
            // Food Tray with Drag-and-Drop to Feed
            VStack(spacing: 4) {
                Text("Перетащи еду прямо в пасть жуку! 👇")
                    .font(.caption2)
                    .foregroundColor(.gray)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FoodItem.catalog) { item in
                            Button(action: { feedFood(item) }) {
                                VStack(spacing: 2) {
                                    Text(item.icon).font(.title)
                                    Text(item.name).font(.system(size: 10, weight: .bold))
                                    Text("🪙 \(item.cost)").font(.system(size: 9, weight: .bold)).foregroundColor(.yellow)
                                }
                                .frame(width: 75, height: 68)
                                .background(Color(red: 0.16, green: 0.18, blue: 0.28))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
        case .bath:
            // Interactive Soap and Shower Tools (Just like Talking Tom!)
            HStack(spacing: 30) {
                // Soap tool
                VStack(spacing: 4) {
                    Text("🧼")
                        .font(.system(size: 40))
                        .padding(8)
                        .background(Color.cyan.opacity(0.2))
                        .clipShape(Circle())
                    Text("Намылить")
                        .font(.system(size: 10, weight: .bold))
                }
                .onTapGesture {
                    latherFoam()
                }
                
                // Shower tool
                VStack(spacing: 4) {
                    Text("🚿")
                        .font(.system(size: 40))
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Circle())
                    Text("Смыть водой")
                        .font(.system(size: 10, weight: .bold))
                }
                .onTapGesture {
                    rinseWithShower()
                }
            }
            
        case .toilet:
            // Real Toilet commode with flush lever!
            VStack(spacing: 8) {
                Button(action: flushToiletServer) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2)
                        Text("Смыть кэш (Спустить бачок)")
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                }
            }
            
        case .bedroom:
            Button(action: toggleSleep) {
                Label(beetle.isSleeping ? "☀️ Разбудить (Доброе утро!)" : "🌙 Выключить сервер (Сон)",
                      systemImage: beetle.isSleeping ? "sun.max.fill" : "moon.fill")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(18)
            }
            
        case .arcade:
            HStack(spacing: 14) {
                Button(action: { showMinigame = true }) {
                    Label("Ловец токенов", systemImage: "gamecontroller.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                }
                Button(action: { showViralSheet = true }) {
                    Label("Чек от ИИ", systemImage: "doc.text.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
        }
    }
    
    // MARK: - Water Stream FX
    private var waterStreamEffect: some View {
        VStack(spacing: 3) {
            ForEach(0..<12) { _ in
                Rectangle()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 3, height: 16)
            }
        }
        .offset(y: -40)
    }
    
    // MARK: - Bottom Navigation
    private var bottomTabBar: some View {
        HStack {
            ForEach(RoomType.allCases) { room in
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        currentRoom = room
                        updateEmotion()
                    }
                }) {
                    VStack(spacing: 3) {
                        Image(systemName: room.icon)
                            .font(.system(size: 20))
                        Text(room.rawValue)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(currentRoom == room ? .orange : .gray)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(currentRoom == room ? Color.orange.opacity(0.15) : Color.clear)
                    .cornerRadius(12)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 10)
        .background(Color(red: 0.07, green: 0.08, blue: 0.12).ignoresSafeArea(edges: .bottom))
    }
    
    // MARK: - Actions
    private func handlePetting() {
        eyeExpression = .happy
        speechText = "Муррр! Чистый синтаксис, приятно гладишь! 🥰"
        let heartId = UUID()
        floatingHearts.append(heartId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            floatingHearts.removeAll(where: { $0 == heartId })
        }
    }
    
    private func handlePoke() {
        isPoked = true
        eyeExpression = .hangry
        speechText = [
            "Ай! Не бей по жвалам!",
            "Тык! За один удар списываю 10 токенов!",
            "У меня от твоих тыков StackOverflow!",
            "Аккуратнее, монитор поцарапаешь!"
        ].randomElement()!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isPoked = false
            eyeExpression = .standard
        }
    }
    
    private func feedFood(_ item: FoodItem) {
        guard tokens >= item.cost else {
            speechText = "Нет токенов! Иди фарми в мини-игре! 🪙"
            return
        }
        tokens -= item.cost
        beetle.hunger = min(100, beetle.hunger + item.hungerGain)
        beetle.tokensEaten += item.cost * 100
        isChewing = true
        eyeExpression = .happy
        speechText = "Ммм! \(item.name) сожран! Токены усвоены! 🤤"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isChewing = false
            eyeExpression = .standard
        }
        persistState()
    }
    
    private func latherFoam() {
        foamAmount = min(1.0, foamAmount + 0.25)
        eyeExpression = .dizzy
        speechText = "Пена пошла! Намыливай тщательнее, баги прячутся в углах! 🧼"
        persistState()
    }
    
    private func rinseWithShower() {
        isWaterFlowing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            isWaterFlowing = false
            foamAmount = 0.0
            beetle.clean = 100.0
            eyeExpression = .happy
            speechText = "Пшшш! Все баги смыты! Код блестит до скрипа! ✨"
            persistState()
        }
    }
    
    private func flushToiletServer() {
        beetle.toilet = 100.0
        eyeExpression = .happy
        speechText = "Вжууух! Кэш и дампы памяти смыты в трубу! Теперь летаю! 🚀"
        persistState()
    }
    
    private func toggleSleep() {
        beetle.isSleeping.toggle()
        if beetle.isSleeping {
            eyeExpression = .sleeping
            speechText = "Zzz... Сервер спит. Лимиты восстанавливаются... 🌙"
        } else {
            beetle.energy = 100.0
            tokens += 50
            eyeExpression = .happy
            speechText = "Доброе утро! Держи утренний бонус +50 токенов! ☀️"
        }
        persistState()
    }
    
    private func updateEmotion() {
        emotionState = BeetleEmotionState.compute(for: beetle, weather: currentWeather, date: Date())
        speechText = emotionState.sarcasticQuote
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
        updateEmotion()
        persistState()
    }
    
    private func persistState() {
        SharedDataManager.shared.saveBeetle(beetle)
        SharedDataManager.shared.saveTokens(tokens)
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
}
