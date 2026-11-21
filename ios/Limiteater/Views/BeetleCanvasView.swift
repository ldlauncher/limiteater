//
//  BeetleCanvasView.swift
//  Limiteater
//  Exact representation of the viral 3D Claude mascot (orange blocky body, 6 pillar legs, < > eyes)
//

import SwiftUI

public enum EyeExpression {
    case standard       // < >
    case happy          // ^ ^
    case sleeping       // - -
    case dizzy          // @ @
    case money          // $ $
    case hangry         // > <
    case sunglasses    // 🕶️
    case matrix         // 0 1
}

public struct BeetleCanvasView: View {
    public var beetle: Beetle
    public var expression: EyeExpression = .standard
    public var foamAmount: Double = 0.0     // 0.0 to 1.0 (soap foam in bathroom)
    public var isChewing: Bool = false
    public var isPoked: Bool = false
    public var legWalkOffset: CGFloat = 0.0
    
    @State private var idleWobble: CGFloat = 0.0
    
    public init(
        beetle: Beetle,
        expression: EyeExpression = .standard,
        foamAmount: Double = 0.0,
        isChewing: Bool = false,
        isPoked: Bool = false,
        legWalkOffset: CGFloat = 0.0
    ) {
        self.beetle = beetle
        self.expression = expression
        self.foamAmount = foamAmount
        self.isChewing = isChewing
        self.isPoked = isPoked
        self.legWalkOffset = legWalkOffset
    }
    
    public var currentExpression: EyeExpression {
        if beetle.isSleeping { return .sleeping }
        if beetle.hunger < 25 { return .hangry }
        if expression != .standard { return expression }
        return .standard
    }
    
    public var body: some View {
        ZStack {
            // Shadow under feet
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 170, height: 26)
                .offset(y: 85)
            
            VStack(spacing: 0) {
                // Top Main Block Body (Orange Rounded Cuboid)
                ZStack {
                    // Left and Right ear-blocks (Side handles)
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.90, green: 0.42, blue: 0.12))
                            .frame(width: 20, height: 42)
                            .offset(x: -8)
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.85, green: 0.38, blue: 0.10))
                            .frame(width: 20, height: 42)
                            .offset(x: 8)
                    }
                    .frame(width: 190)
                    
                    // Main Cuboid Front Face
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.98, green: 0.52, blue: 0.18),
                                    Color(red: 0.91, green: 0.43, blue: 0.12)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 170, height: 110)
                        .overlay(
                            // 3D Bevel Highlight
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.25), lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 5)
                    
                    // Eyes (< > or dynamic states)
                    renderEyes()
                    
                    // Soap Foam Overlay (if bathing)
                    if foamAmount > 0.05 {
                        soapFoamLayer()
                    }
                }
                .offset(y: isChewing ? -4 : 0)
                
                // Bottom 6 Pillar Legs (3 on left, 3 on right)
                HStack(spacing: 6) {
                    // Left 3 legs
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.86, green: 0.38, blue: 0.10))
                            .frame(width: 18, height: 38)
                            .offset(y: legWalkOffset * (i % 2 == 0 ? 1 : -1))
                    }
                    
                    Spacer().frame(width: 20) // Gap between leg clusters
                    
                    // Right 3 legs
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.82, green: 0.35, blue: 0.09))
                            .frame(width: 18, height: 38)
                            .offset(y: -legWalkOffset * (i % 2 == 0 ? 1 : -1))
                    }
                }
                .frame(width: 160)
                .offset(y: -2)
            }
            .scaleEffect(isPoked ? 0.92 : (1.0 + idleWobble))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPoked)
        }
        .frame(width: 220, height: 200)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                idleWobble = 0.02
            }
        }
    }
    
    // MARK: - Eye Expression Renderer
    @ViewBuilder
    private func renderEyes() -> some View {
        HStack(spacing: 48) {
            switch currentExpression {
            case .standard:
                // Iconic < > eyes
                Text("<")
                    .font(.system(size: 34, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.14))
                Text(">")
                    .font(.system(size: 34, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.14))
                
            case .happy:
                Text("^")
                    .font(.system(size: 36, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.14))
                Text("^")
                    .font(.system(size: 36, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.14))
                
            case .sleeping:
                Text("-")
                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                Text("-")
                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.2))
                
            case .hangry:
                Text(">")
                    .font(.system(size: 34, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.8, green: 0.1, blue: 0.1))
                Text("<")
                    .font(.system(size: 34, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(red: 0.8, green: 0.1, blue: 0.1))
                
            case .dizzy:
                Text("@")
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.purple)
                Text("@")
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.purple)
                
            case .money:
                Text("$")
                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.yellow)
                Text("$")
                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.yellow)
                
            case .sunglasses:
                Text("🕶️")
                    .font(.system(size: 36))
                
            case .matrix:
                Text("0")
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.green)
                Text("1")
                    .font(.system(size: 30, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.green)
            }
        }
        .offset(y: -5)
    }
    
    // MARK: - Soap Foam Bubbles
    private func soapFoamLayer() -> some View {
        ZStack {
            ForEach(0..<Int(foamAmount * 14), id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: CGFloat(16 + (i * 3) % 18), height: CGFloat(16 + (i * 3) % 18))
                    .overlay(Circle().stroke(Color.cyan.opacity(0.4), lineWidth: 1.5))
                    .offset(
                        x: CGFloat(((i * 37) % 140) - 70),
                        y: CGFloat(((i * 29) % 80) - 40)
                    )
            }
        }
        .frame(width: 170, height: 110)
    }
}
