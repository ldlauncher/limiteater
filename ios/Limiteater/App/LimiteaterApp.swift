//
//  LimiteaterApp.swift
//  Limiteater
//  iOS 15+ Main App Entry Point
//

import SwiftUI

@main
struct LimiteaterApp: App {
    var body: some Scene {
        WindowGroup {
            RootGameView()
                .preferredColorScheme(.dark)
        }
    }
}
