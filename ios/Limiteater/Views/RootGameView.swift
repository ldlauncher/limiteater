//
//  RootGameView.swift
//  Limiteater
//  Interactive My Talking Tom style gameplay for iOS 15+
//

import SwiftUI
import Combine

public enum ActiveMinigame: String, Identifiable {
    case tokenCatcher = "tokenCatcher"
    case flappyBug = "flappyBug"
    case memoryCards = "memoryCards"
    case whackABug = "whackABug"
    
    public var id: String { rawValue }
}

public struct RootGameView: View {
    @State private var currentRoom: RoomType = .arcade
    @State private var beetle: Beetle = SharedDataManager.shared.loadBeetle()
    @State private var tokens: Int = SharedDataManager.shared.loadTokens()
    @State private var speechText: String = "Выбирай игру! Фарми токены на серверах! 🪙"
    
    // Interactive Bath Tools (Drag-to-Wash)
    @State private var soapOffset: CGSize = .zero
    @State private var isDraggingSoap: Bool = false
    @State private var showerOffset: CGSize = .zero
    @State private var isDraggingShower: Bool = false
    @State private var foamAmount: Double = 0.0
    @State private var isWaterFlowing: Bool = false
    
    // Interactive Kitchen (3 Swipeable Plates)
    @State private var currentPlateIndex: Int = 0
    @State private var draggedFood: FoodItem? = nil
    @State private var foodDragOffset: CGSize = .zero
    
    // Interactive Toilet (Commode & Flush)
    @State private var isFlushing: Bool = false
    @State private var flushLeverAngle: Double = 0.0
    
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
    @State private var activeMinigame: ActiveMinigame? = nil
    @State private var showViralSheet: Bool = false
    
    let timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    
    public init() {}
    
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
                    // Commode beneath beetle when in toilet room
                    if currentRoom == .toilet {
                        toiletCommodeGraphic
                            .offset(y: 40)
                    }
                    
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
                    
                    // Toilet flush swirl effect
                    if isFlushing {
                        toiletFlushEffect
                    }
                }
                .frame(height: 220)
                
                Spacer()
                
                // Interactive Room Props (Soap/Shower, 3 Plates, Commode Flush, 4 Arcade Games)
                roomInteractiveArea
                    .frame(height: 125)
                    .padding(.bottom, 6)
                
                // Talking Tom 5-Tab Bar
                bottomTabBar
            }
            
            // Draggable Soap Tool (Floating overlay in Bath)
            if currentRoom == .bath {
                draggableSoapOverlay
                draggableShowerOverlay
            }
        }
        .sheet(isPresented: $showMultiPetSheet) {
            MultiPetSheetView(currentBeetle: $beetle)
        }
        .sheet(item: $activeMinigame) { game in
            switch game {
            case .tokenCatcher:
                TokenCatcherGameView(tokens: $tokens, beetle: $beetle)
            case .flappyBug:
                FlappyBugGameView(tokens: $tokens, beetle: $beetle)
            case .memoryCards:
                MemoryCardsGameView(tokens: $tokens, beetle: $beetle)
            case .whackABug:
                WhackABugGameView(tokens: $tokens, beetle: $beetle)
            }
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
    
    // MARK: - Toilet Commode Graphic
    private var toiletCommodeGraphic: some View {
        ZStack {
            // Commode Tank (Задний бачок)
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.white, Color(white: 0.88)]), startPoint: .top, endPoint: .bottom))
                .frame(width: 140, height: 75)
                .offset(y: -25)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                        .offset(y: -25)
                )
            
            // Flush Lever on the Tank
            HStack {
                Spacer()
                ZStack {
                    Capsule()
                        .fill(Color.gray)
                        .frame(width: 24, height: 7)
                        .rotationEffect(.degrees(flushLeverAngle), anchor: .leading)
                        .onTapGesture {
                            flushToiletServer()
                        }
                }
                .offset(x: -8, y: -45)
            }
            .frame(width: 140)
            
            // Commode Bowl & Seat (Ободок унитаза)
            Ellipse()
                .fill(Color.white)
                .frame(width: 175, height: 80)
                .offset(y: 45)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 4)
            
            // Inner Bowl Water
            Ellipse()
                .fill(Color.cyan.opacity(0.4))
                .frame(width: 125, height: 50)
                .offset(y: 45)
        }
    }
    
    // MARK: - Swirling Flush Animation
    private var toiletFlushEffect: some View {
        VStack(spacing: 4) {
            Text("🌀 0101010101 🌀")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            Text("КЭШ ОЧИЩЕН!")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
        }
        .offset(y: 40)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Draggable Soap in Bath
    private var draggableSoapOverlay: some View {
        VStack {
            Spacer()
            HStack {
                // Soap tool
                VStack(spacing: 2) {
                    Text("🧼")
                        .font(.system(size: 38))
                    Text("Мыло")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.cyan.opacity(0.3))
                .clipShape(Circle())
                .offset(soapOffset)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            soapOffset = val.translation
                            isDraggingSoap = true
                            // If user scrubs across the center where beetle is, lather foam
                            if abs(val.translation.height) > 40 || abs(val.translation.width) > 30 {
                                latherFoam()
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                soapOffset = .zero
                                isDraggingSoap = false
                            }
                        }
                )
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 160)
        }
    }
    
    // MARK: - Draggable Shower in Bath
    private var draggableShowerOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                // Shower tool
                VStack(spacing: 2) {
                    Text("🚿")
                        .font(.system(size: 38))
                    Text("Душ")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.blue.opacity(0.3))
                .clipShape(Circle())
                .offset(showerOffset)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            showerOffset = val.translation
                            isDraggingShower = true
                            isWaterFlowing = true
                            rinseWithShower()
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                showerOffset = .zero
                                isDraggingShower = false
                                isWaterFlowing = false
                            }
                        }
                )
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 160)
        }
    }
    
    // MARK: - Interactive Room Props
    @ViewBuilder
    private var roomInteractiveArea: some View {
        switch currentRoom {
        case .kitchen:
            // 3 Swipeable Plates (Тарелки с едой)
            kitchenPlatesCarousel
            
        case .bath:
            // Instructions for Bath
            VStack(spacing: 6) {
                Text("Тяни 🧼 мыло пальцем на жука, чтобы напенить!")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.cyan)
                Text("Затем тяни 🚿 душ, чтобы смыть всю пену водой!")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
        case .toilet:
            // Real Toilet commode with flush lever!
            VStack(spacing: 6) {
                Button(action: flushToiletServer) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title2)
                        Text("Смыть кэш (Спустить бачок) 🚽")
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                }
                Text("Жук сидит на унитазе и освобождает контекст!")
                    .font(.caption2)
                    .foregroundColor(.gray)
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
            // 4 Mini-Games Carousel/Row
            arcadeGamesRow
        }
    }
    
    // MARK: - Kitchen Plates Carousel
    private var kitchenPlatesCarousel: some View {
        VStack(spacing: 4) {
            // Plate selector tabs
            HStack(spacing: 12) {
                plateTabButton(title: "🍪 Закуски", index: 0)
                plateTabButton(title: "🍔 Фастфуд", index: 1)
                plateTabButton(title: "💎 Премиум", index: 2)
            }
            
            // Plate foods
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(foodForPlate(currentPlateIndex)) { item in
                        Button(action: { feedFood(item) }) {
                            VStack(spacing: 2) {
                                Text(item.icon).font(.title)
                                Text(item.name).font(.system(size: 9, weight: .bold))
                                    .lineLimit(1)
                                Text("🪙 \(item.cost)").font(.system(size: 8, weight: .bold)).foregroundColor(.yellow)
                            }
                            .frame(width: 78, height: 68)
                            .background(Color(red: 0.16, green: 0.18, blue: 0.28))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.4), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func plateTabButton(title: String, index: Int) -> some View {
        Button(action: { currentPlateIndex = index }) {
            Text(title)
                .font(.caption.weight(currentPlateIndex == index ? .bold : .regular))
                .foregroundColor(currentPlateIndex == index ? .orange : .gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(currentPlateIndex == index ? Color.orange.opacity(0.2) : Color.clear)
                .cornerRadius(10)
        }
    }
    
    private func foodForPlate(_ index: Int) -> [FoodItem] {
        switch index {
        case 0:
            return [
                FoodItem(name: "Промпт-печенье", icon: "🍪", cost: 2, hungerGain: 15, quote: "Хрум! Базовый промпт усвоен!"),
                FoodItem(name: "Байт-сэндвич", icon: "🥪", cost: 5, hungerGain: 25, quote: "Байты в животе — сытость в коде!"),
                FoodItem(name: "Кофе для дебага", icon: "☕", cost: 4, hungerGain: 20, quote: "Эспрессо разогнал тактовую частоту!")
            ]
        case 1:
            return [
                FoodItem(name: "JSON-Бургер", icon: "🍔", cost: 10, hungerGain: 40, quote: "Слоёный JSON прямо в оперативку!"),
                FoodItem(name: "Пицца 200 OK", icon: "🍕", cost: 12, hungerGain: 45, quote: "Статус 200: пицца принята успешно!"),
                FoodItem(name: "Шаурма 429", icon: "🌯", cost: 8, hungerGain: 35, quote: "Острая шаурма превысила лимит запросов!")
            ]
        default:
            return [
                FoodItem(name: "API Ключ Pro", icon: "💎", cost: 25, hungerGain: 80, quote: "PRO-подписка активирована! Вкусно!"),
                FoodItem(name: "GPU-Стейк", icon: "🥩", cost: 30, hungerGain: 95, quote: "Стейк пожарен прямо на NVIDIA H100!"),
                FoodItem(name: "Сингулярность", icon: "🍰", cost: 20, hungerGain: 70, quote: "Кусочек торта из горизонта событий!")
            ]
        }
    }
    
    // MARK: - Arcade Games Row (All 4 Mini-Games)
    private var arcadeGamesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Game 1: Token Catcher
                gameCard(title: "Ловец токенов", icon: "🪙", subtitle: "Уворачивайся от 429", color: .green) {
                    activeMinigame = .tokenCatcher
                }
                
                // Game 2: Flappy Bug
                gameCard(title: "Flappy Bug", icon: "🪽", subtitle: "Побег из серверной", color: .cyan) {
                    activeMinigame = .flappyBug
                }
                
                // Game 3: Memory Cards
                gameCard(title: "Нейро-Память", icon: "🃏", subtitle: "Ищи пары токенов", color: .purple) {
                    activeMinigame = .memoryCards
                }
                
                // Game 4: Whack-a-Bug
                gameCard(title: "Дебаггер", icon: "🔨", subtitle: "Выбивай баги", color: .orange) {
                    activeMinigame = .whackABug
                }
                
                // AI Receipt
                gameCard(title: "Чек от ИИ", icon: "🧾", subtitle: "Счёт за токены", color: .pink) {
                    showViralSheet = true
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func gameCard(title: String, icon: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(icon)
                    .font(.system(size: 26))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            }
            .frame(width: 95, height: 75)
            .background(Color(red: 0.14, green: 0.16, blue: 0.25))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.8), lineWidth: 1.5))
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
        speechText = item.quote
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isChewing = false
            eyeExpression = .standard
        }
        persistState()
    }
    
    private func latherFoam() {
        foamAmount = min(1.0, foamAmount + 0.08)
        eyeExpression = .dizzy
        speechText = "Пена пошла! Намыливай тщательнее, баги прячутся в углах! 🧼"
        persistState()
    }
    
    private func rinseWithShower() {
        foamAmount = max(0.0, foamAmount - 0.1)
        if foamAmount <= 0.05 {
            foamAmount = 0.0
            beetle.clean = 100.0
            eyeExpression = .happy
            speechText = "Пшшш! Все баги смыты! Код блестит до скрипа! ✨"
        }
        persistState()
    }
    
    private func flushToiletServer() {
        flushLeverAngle = 35.0
        isFlushing = true
        beetle.toilet = 100.0
        eyeExpression = .happy
        speechText = "Вжууух! Кэш и дампы памяти смыты в трубу! Теперь летаю! 🚀"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            flushLeverAngle = 0.0
            isFlushing = false
        }
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
