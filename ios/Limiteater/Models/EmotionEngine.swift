//
//  EmotionEngine.swift
//  Limiteater
//  Dynamic Mood & Emotion Matrix based on Weather, Time of Day, and Tamagotchi Needs
//

import Foundation
import SwiftUI

public enum TimeOfDayState: String, CaseIterable, Codable {
    case morning = "Утро"
    case day = "День"
    case evening = "Вечер"
    case night = "Ночь"
    case deepNight = "3 Ночи (Вайбкодер)"
    
    public static func current(from date: Date = Date()) -> TimeOfDayState {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .day
        case 18..<23: return .evening
        case 23..<24, 0..<3: return .night
        default: return .deepNight
        }
    }
}

public enum WeatherType: String, CaseIterable, Codable {
    case sunny = "Ясно"
    case cloudy = "Облачно"
    case rainy = "Дождь"
    case stormy = "Гроза"
    case snowy = "Снег"
    
    public var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .stormy: return "bolt.fill"
        case .snowy: return "snowflake"
        }
    }
}

public struct BeetleEmotionState: Identifiable, Codable {
    public var id: String { "\(timeOfDay.rawValue)_\(weather.rawValue)_\(dominantNeed)" }
    public var timeOfDay: TimeOfDayState
    public var weather: WeatherType
    public var dominantNeed: String
    
    public var emotionTitle: String
    public var sarcasticQuote: String
    public var accessoryEmoji: String
    public var eyesType: String        // "normal", "starving", "sleepy", "sunglasses", "matrix", "red_eyes"
    public var auraColorHex: String
    
    public static func compute(for beetle: Beetle, weather: WeatherType = .sunny, date: Date = Date()) -> BeetleEmotionState {
        let time = TimeOfDayState.current(from: date)
        
        // 1. Sleeping state overrides
        if beetle.isSleeping {
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Сон",
                emotionTitle: "Сервер выключен",
                sarcasticQuote: "Zzz... восстанавливаю лимиты до 4 утра...",
                accessoryEmoji: "💤",
                eyesType: "sleepy",
                auraColorHex: "#3a86ff"
            )
        }
        
        // 2. Critical Needs overrides
        if beetle.hunger < 25 {
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Голод",
                emotionTitle: "Злой Лимитоед",
                sarcasticQuote: "Где мои токены, кожаный мешок?! Щас сожру прод!",
                accessoryEmoji: "🍴",
                eyesType: "starving",
                auraColorHex: "#e63946"
            )
        }
        
        if beetle.toilet < 25 {
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Кэш",
                emotionTitle: "Переполнение стека",
                sarcasticQuote: "Срочно сбрось кэш и удали node_modules, я лопну!",
                accessoryEmoji: "💥",
                eyesType: "starving",
                auraColorHex: "#9d4edd"
            )
        }
        
        if beetle.clean < 25 {
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Грязь",
                emotionTitle: "Забагованный",
                sarcasticQuote: "Весь в warning'ах и синтаксических ошибках! Отмой меня!",
                accessoryEmoji: "🐛",
                eyesType: "matrix",
                auraColorHex: "#06d6a0"
            )
        }
        
        // 3. Time & Weather combined states (Vibrant procedural matrix)
        switch (time, weather) {
        case (.deepNight, _):
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Ночной кодинг",
                emotionTitle: "Вайбкодер 3:00 AM",
                sarcasticQuote: "Кто вообще пишет код в 3 часа ночи?! Дай ещё кофе!",
                accessoryEmoji: "☕",
                eyesType: "red_eyes",
                auraColorHex: "#f72585"
            )
            
        case (.morning, .sunny):
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Бодрость",
                emotionTitle: "Свежий деплой",
                sarcasticQuote: "Доброе утро! Солнце светит, лимиты обновлены!",
                accessoryEmoji: "☀️",
                eyesType: "normal",
                auraColorHex: "#ffd166"
            )
            
        case (.morning, .rainy):
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Хмурое утро",
                emotionTitle: "Смытый спринт",
                sarcasticQuote: "Дождь идёт, деплой течёт. Хочу горячего какао из токенов.",
                accessoryEmoji: "🌧️",
                eyesType: "sleepy",
                auraColorHex: "#457b9d"
            )
            
        case (_, .stormy):
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Шторм",
                emotionTitle: "Ошибка 502 / Молния",
                sarcasticQuote: "В дата-центре мигают лампочки! Антенны бьют током!",
                accessoryEmoji: "⚡",
                eyesType: "matrix",
                auraColorHex: "#7209b7"
            )
            
        case (_, .snowy):
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Холод",
                emotionTitle: "Крио-кулер",
                sarcasticQuote: "Охладил видеокарту до нуля. Закутай меня в шарфик!",
                accessoryEmoji: "🧣",
                eyesType: "normal",
                auraColorHex: "#a8dadc"
            )
            
        case (.day, .sunny):
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Чилл",
                emotionTitle: "Сеньор на чилле",
                sarcasticQuote: "Код работает, тесты зеленые, токены капают. Идеально.",
                accessoryEmoji: "🕶️",
                eyesType: "sunglasses",
                auraColorHex: "#ffb703"
            )
            
        default:
            return BeetleEmotionState(
                timeOfDay: time,
                weather: weather,
                dominantNeed: "Норма",
                emotionTitle: "Сытый Лимитоед",
                sarcasticQuote: "Пока всё тихо. Подкинь пару промптов для разминки!",
                accessoryEmoji: "🪙",
                eyesType: "normal",
                auraColorHex: "#fb8500"
            )
        }
    }
}
