//
//  SharedDataManager.swift
//  Limiteater
//  Shared data between Main App and WidgetKit (iOS 15+)
//

import Foundation

public final class SharedDataManager {
    public static let shared = SharedDataManager()
    
    // Replace with your real App Group ID in Xcode
    public let appGroupSuite = "group.com.limiteater.app"
    
    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupSuite) ?? UserDefaults.standard
    }
    
    private let petKey = "saved_beetle_key"
    private let tokensKey = "saved_tokens_key"
    
    public func saveBeetle(_ beetle: Beetle) {
        if let encoded = try? JSONEncoder().encode(beetle) {
            defaults.set(encoded, forKey: petKey)
        }
    }
    
    public func loadBeetle() -> Beetle {
        if let data = defaults.data(forKey: petKey),
           let beetle = try? JSONDecoder().decode(Beetle.self, from: data) {
            return beetle
        }
        return Beetle(name: "Клодик")
    }
    
    public func saveTokens(_ count: Int) {
        defaults.set(count, forKey: tokensKey)
    }
    
    public func loadTokens() -> Int {
        let val = defaults.integer(forKey: tokensKey)
        return val == 0 ? 350 : val
    }
}
