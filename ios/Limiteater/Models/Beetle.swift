//
//  Beetle.swift
//  Limiteater (Жук-Лимитоед)
//  iOS 15+
//

import Foundation
import SwiftUI

public enum RoomType: String, CaseIterable, Identifiable, Codable {
    case kitchen = "Кухня"
    case toilet = "Кэш"
    case bath = "Линтер"
    case bedroom = "Спальня"
    case arcade = "Фарм"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .kitchen: return "fork.knife"
        case .toilet: return "trash.fill"
        case .bath: return "sparkles"
        case .bedroom: return "bed.double.fill"
        case .arcade: return "gamecontroller.fill"
        }
    }
}

public struct FoodItem: Identifiable, Codable {
    public var id: String
    public var name: String
    public var icon: String
    public var cost: Int
    public var hungerGain: Double
    public var quote: String
    
    public init(id: String = UUID().uuidString, name: String, icon: String, cost: Int, hungerGain: Double, quote: String = "") {
        self.id = id
        self.name = name
        self.icon = icon
        self.cost = cost
        self.hungerGain = hungerGain
        self.quote = quote.isEmpty ? "Ммм! \(name) сожран! Токены усвоены! 🤤" : quote
    }
    
    public static let catalog: [FoodItem] = [
        FoodItem(id: "cookie", name: "Промпт-печенье", icon: "🍪", cost: 2, hungerGain: 15, quote: "Хрум! Базовый промпт усвоен!"),
        FoodItem(id: "burger", name: "JSON-Бургер", icon: "🍔", cost: 10, hungerGain: 40, quote: "Слоёный JSON прямо в оперативку!"),
        FoodItem(id: "shawarma", name: "Шаурма 429", icon: "🌯", cost: 8, hungerGain: 35, quote: "Острая шаурма превысила лимит запросов!"),
        FoodItem(id: "api_key", name: "API Ключ Pro", icon: "💎", cost: 25, hungerGain: 80, quote: "PRO-подписка активирована! Вкусно!")
    ]
}

public struct Beetle: Identifiable, Codable {
    public var id: UUID = UUID()
    public var name: String
    public var level: Int = 1
    public var hunger: Double = 80.0     // 0 - 100 (Кухня)
    public var toilet: Double = 85.0     // 0 - 100 (Кэш / Туалет)
    public var clean: Double = 70.0      // 0 - 100 (Линтер / Ванна)
    public var energy: Double = 90.0     // 0 - 100 (Сон / Спальня)
    public var tokensEaten: Int = 1500
    public var isSleeping: Bool = false
    public var birthDate: Date = Date()
    
    public init(id: UUID = UUID(), name: String, level: Int = 1, hunger: Double = 80.0, toilet: Double = 85.0, clean: Double = 70.0, energy: Double = 90.0, tokensEaten: Int = 1500, isSleeping: Bool = false, birthDate: Date = Date()) {
        self.id = id
        self.name = name
        self.level = level
        self.hunger = hunger
        self.toilet = toilet
        self.clean = clean
        self.energy = energy
        self.tokensEaten = tokensEaten
        self.isSleeping = isSleeping
        self.birthDate = birthDate
    }
    
    public var moodDescription: String {
        if isSleeping { return "Спит (Лимиты восстанавливаются...)" }
        if hunger < 25 { return "Умирает с голоду! Срочно дай токенов!" }
        if toilet < 25 { return "Срочно очисти кэш и удали node_modules!" }
        if clean < 25 { return "Весь в багах! Запусти линтер!" }
        if energy < 25 { return "Глаза слипаются... уложи в спальню!" }
        return "Вайбкодит! Настроение отличное! 🚀"
    }
    
    public var randomQuote: String {
        if isSleeping { return "Zzz... снится чистый код без багов..." }
        if hunger < 30 { return "Где мои токены, кожаный мешок? 😈" }
        return [
            "Ты опять сделал запрос к БД в цикле?",
            "Дай токенов! Иначе контекст схлопнется!",
            "Случайно скормил 500k токенов за 2 секунды!",
            "Твой код прекрасен, но добавь ещё токенов!"
        ].randomElement() ?? "Жду токены!"
    }
}
