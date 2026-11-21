//
//  LimiteaterWidget.swift
//  LimiteaterWidgetExtension
//  iOS 15+ WidgetKit: Real-time Weather, Time of Day & Dynamic Mood Matrix
//

import WidgetKit
import SwiftUI

struct BeetleWidgetEntry: TimelineEntry {
    let date: Date
    let beetle: Beetle
    let emotion: BeetleEmotionState
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BeetleWidgetEntry {
        let pet = Beetle(name: "Клодик")
        let emotion = BeetleEmotionState.compute(for: pet, weather: .sunny, date: Date())
        return BeetleWidgetEntry(date: Date(), beetle: pet, emotion: emotion)
    }

    func getSnapshot(in context: Context, completion: @escaping (BeetleWidgetEntry) -> ()) {
        let beetle = SharedDataManager.shared.loadBeetle()
        let emotion = BeetleEmotionState.compute(for: beetle, weather: .sunny, date: Date())
        let entry = BeetleWidgetEntry(date: Date(), beetle: beetle, emotion: emotion)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let beetle = SharedDataManager.shared.loadBeetle()
        let currentDate = Date()
        
        // Dynamic simulated Apple Weather condition based on hour / season
        let simulatedWeather: WeatherType = {
            let hour = Calendar.current.component(.hour, from: currentDate)
            if hour >= 21 || hour < 6 { return .cloudy }
            if hour % 3 == 0 { return .rainy }
            return .sunny
        }()
        
        var entries: [BeetleWidgetEntry] = []
        
        // Generate hourly entries for dynamic time-of-day shifts (Morning, Day, Evening, 3AM Vibe-coding)
        for hourOffset in 0..<4 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let emotion = BeetleEmotionState.compute(for: beetle, weather: simulatedWeather, date: entryDate)
            entries.append(BeetleWidgetEntry(date: entryDate, beetle: beetle, emotion: emotion))
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct LimiteaterWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.14)
            
            switch family {
            case .systemSmall:
                smallWidgetView
            default:
                mediumWidgetView
            }
        }
    }
    
    // MARK: - Small Widget
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Top badges (Weather & Time)
            HStack {
                HStack(spacing: 3) {
                    Image(systemName: entry.emotion.weather.icon)
                        .font(.system(size: 9))
                    Text(entry.emotion.timeOfDay.rawValue)
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
                
                Spacer()
                
                Text(entry.emotion.accessoryEmoji)
                    .font(.system(size: 14))
            }
            
            HStack(spacing: 4) {
                Text(entry.beetle.name)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                Text("Lvl \(entry.beetle.level)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            Text(entry.emotion.emotionTitle)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.yellow)
                .lineLimit(1)
            
            Text("\"\(entry.emotion.sarcasticQuote)\"")
                .font(.system(size: 8))
                .italic()
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            Spacer()
            
            // Hunger progress bar
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Сытость:")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(entry.beetle.hunger))%")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.orange)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(entry.beetle.hunger / 100.0))
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(10)
    }
    
    // MARK: - Medium Widget
    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(entry.emotion.accessoryEmoji)
                    .font(.system(size: 32))
                Text(entry.beetle.name)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 3) {
                    Image(systemName: entry.emotion.weather.icon)
                        .font(.system(size: 9))
                    Text(entry.emotion.weather.rawValue)
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.cyan)
            }
            .frame(width: 85)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(entry.emotion.emotionTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.yellow)
                    Spacer()
                    Text(entry.emotion.timeOfDay.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Text("\"\(entry.emotion.sarcasticQuote)\"")
                    .font(.system(size: 10))
                    .italic()
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                
                Spacer()
                
                HStack(spacing: 8) {
                    needMiniIndicator(label: "🍔", val: entry.beetle.hunger, color: .orange)
                    needMiniIndicator(label: "🚽", val: entry.beetle.toilet, color: .purple)
                    needMiniIndicator(label: "🧼", val: entry.beetle.clean, color: .green)
                    needMiniIndicator(label: "⚡", val: entry.beetle.energy, color: .cyan)
                }
            }
        }
        .padding(12)
    }
    
    private func needMiniIndicator(label: String, val: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label).font(.system(size: 9))
            Text("\(Int(val))%").font(.system(size: 8, weight: .bold)).foregroundColor(color)
        }
    }
}

@main
struct LimiteaterWidget: Widget {
    let kind: String = "LimiteaterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LimiteaterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Жук-Лимитоед")
        .description("Следи за настроением жука в зависимости от погоды, времени суток и сытости!")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
