//
//  LimiteaterWidget.swift
//  LimiteaterWidgetExtension
//  iOS 15+ WidgetKit: Show Beetle's Live Mood & Needs on Home & Lock Screen
//

import WidgetKit
import SwiftUI

struct BeetleWidgetEntry: TimelineEntry {
    let date: Date
    let beetle: Beetle
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BeetleWidgetEntry {
        BeetleWidgetEntry(date: Date(), beetle: Beetle(name: "Клодик"))
    }

    func getSnapshot(in context: Context, completion: @escaping (BeetleWidgetEntry) -> ()) {
        let beetle = SharedDataManager.shared.loadBeetle()
        let entry = BeetleWidgetEntry(date: Date(), beetle: beetle)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let beetle = SharedDataManager.shared.loadBeetle()
        let currentDate = Date()
        
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let entry = BeetleWidgetEntry(date: currentDate, beetle: beetle)
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("🪲")
                    .font(.title2)
                Spacer()
                Text("Lvl \(entry.beetle.level)")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.orange)
            }
            
            Text(entry.beetle.name)
                .font(.headline)
                .bold()
                .foregroundColor(.white)
            
            Text(entry.beetle.isSleeping ? "💤 Спит..." : (entry.beetle.hunger < 30 ? "🔥 Голоден!" : "🚀 Вайбкодит"))
                .font(.caption)
                .foregroundColor(entry.beetle.hunger < 30 ? .red : .green)
            
            Spacer()
            
            // Hunger progress
            VStack(alignment: .leading, spacing: 2) {
                Text("Сытость: \(Int(entry.beetle.hunger))%")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.orange)
                            .frame(width: geo.size.width * CGFloat(entry.beetle.hunger / 100.0))
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(12)
    }
    
    // MARK: - Medium Widget
    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .center, spacing: 4) {
                Text("🪲")
                    .font(.system(size: 40))
                Text(entry.beetle.name)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
            }
            .frame(width: 90)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.beetle.moodDescription)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.orange)
                    .lineLimit(2)
                
                Text("\"\(entry.beetle.randomQuote)\"")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.secondary)
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
        .padding(14)
    }
    
    private func needMiniIndicator(label: String, val: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label).font(.system(size: 9))
            Text("\(Int(val))%").font(.system(size: 8, weight: .heavy)).foregroundColor(color)
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
        .description("Следи за сытостью и настроением твоего лимитоеда прямо с экрана!")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
