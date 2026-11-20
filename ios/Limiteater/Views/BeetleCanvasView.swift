//
//  BeetleCanvasView.swift
//  Limiteater
//  SwiftUI Canvas procedural animated vector rendering of the Limit-Eater Beetle
//

import SwiftUI

public struct BeetleCanvasView: View {
    public var beetle: Beetle
    public var isChewing: Bool = false
    public var isPoked: Bool = false
    
    @State private var breathScale: CGFloat = 1.0
    @State private var legWiggle: CGFloat = 0.0
    
    public init(beetle: Beetle, isChewing: Bool = false, isPoked: Bool = false) {
        self.beetle = beetle
        self.isChewing = isChewing
        self.isPoked = isPoked
    }
    
    public var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2 + 10)
            
            // 1. Glow / Aura
            let auraRect = CGRect(x: center.x - 70, y: center.y - 60, width: 140, height: 120)
            let auraColor = beetle.isSleeping ? Color.cyan.opacity(0.2) :
                            (beetle.hunger < 25 ? Color.red.opacity(0.3) : Color.orange.opacity(0.25))
            context.fill(Path(ellipseIn: auraRect), with: .color(auraColor))
            
            // 2. Legs (6 legs)
            var legPath = Path()
            // Left
            legPath.move(to: CGPoint(x: center.x - 45, y: center.y - 20))
            legPath.addQuadCurve(to: CGPoint(x: center.x - 85, y: center.y - 10 + legWiggle),
                                 control: CGPoint(x: center.x - 75, y: center.y - 35))
            legPath.move(to: CGPoint(x: center.x - 50, y: center.y + 10))
            legPath.addQuadCurve(to: CGPoint(x: center.x - 90, y: center.y + 25 - legWiggle),
                                 control: CGPoint(x: center.x - 80, y: center.y + 10))
            legPath.move(to: CGPoint(x: center.x - 45, y: center.y + 40))
            legPath.addQuadCurve(to: CGPoint(x: center.x - 85, y: center.y + 65 + legWiggle),
                                 control: CGPoint(x: center.x - 75, y: center.y + 55))
            // Right
            legPath.move(to: CGPoint(x: center.x + 45, y: center.y - 20))
            legPath.addQuadCurve(to: CGPoint(x: center.x + 85, y: center.y - 10 - legWiggle),
                                 control: CGPoint(x: center.x + 75, y: center.y - 35))
            legPath.move(to: CGPoint(x: center.x + 50, y: center.y + 10))
            legPath.addQuadCurve(to: CGPoint(x: center.x + 90, y: center.y + 25 + legWiggle),
                                 control: CGPoint(x: center.x + 80, y: center.y + 10))
            legPath.move(to: CGPoint(x: center.x + 45, y: center.y + 40))
            legPath.addQuadCurve(to: CGPoint(x: center.x + 85, y: center.y + 65 - legWiggle),
                                 control: CGPoint(x: center.x + 75, y: center.y + 55))
            
            context.stroke(legPath, with: .color(Color(red: 0.75, green: 0.28, blue: 0.1)), lineWidth: 7)
            
            // 3. Antennae with Star-like feelers
            var antPath = Path()
            antPath.move(to: CGPoint(x: center.x - 25, y: center.y - 50))
            antPath.addQuadCurve(to: CGPoint(x: center.x - 60, y: center.y - 90),
                                control: CGPoint(x: center.x - 45, y: center.y - 75))
            antPath.move(to: CGPoint(x: center.x + 25, y: center.y - 50))
            antPath.addQuadCurve(to: CGPoint(x: center.x + 60, y: center.y - 90),
                                control: CGPoint(x: center.x + 45, y: center.y - 75))
            context.stroke(antPath, with: .color(Color(red: 0.85, green: 0.35, blue: 0.1)), lineWidth: 5)
            
            // Antenna Tips
            context.fill(Path(ellipseIn: CGRect(x: center.x - 67, y: center.y - 97, width: 14, height: 14)),
                         with: .color(.yellow))
            context.fill(Path(ellipseIn: CGRect(x: center.x + 53, y: center.y - 97, width: 14, height: 14)),
                         with: .color(.yellow))
            
            // 4. Main Body Shell (Chubby Orange Crab-Beetle)
            let bodyRect = CGRect(x: center.x - 60, y: center.y - 50, width: 120, height: 105)
            context.fill(Path(ellipseIn: bodyRect), with: .color(Color(red: 0.93, green: 0.40, blue: 0.18)))
            
            // Carapace highlight
            let wingShadow = CGRect(x: center.x - 2, y: center.y - 50, width: 55, height: 100)
            context.fill(Path(ellipseIn: wingShadow), with: .color(Color(red: 0.80, green: 0.28, blue: 0.12).opacity(0.6)))
            
            // 5. Eyes
            if beetle.isSleeping {
                // Closed eyes (curves)
                var eyeClosedPath = Path()
                eyeClosedPath.move(to: CGPoint(x: center.x - 35, y: center.y - 15))
                eyeClosedPath.addQuadCurve(to: CGPoint(x: center.x - 10, y: center.y - 15),
                                          control: CGPoint(x: center.x - 22, y: center.y - 7))
                eyeClosedPath.move(to: CGPoint(x: center.x + 10, y: center.y - 15))
                eyeClosedPath.addQuadCurve(to: CGPoint(x: center.x + 35, y: center.y - 15),
                                          control: CGPoint(x: center.x + 22, y: center.y - 7))
                context.stroke(eyeClosedPath, with: .color(.black), lineWidth: 4)
            } else {
                // Open big eyes
                let leftEye = CGRect(x: center.x - 35, y: center.y - 25, width: 24, height: 26)
                let rightEye = CGRect(x: center.x + 11, y: center.y - 25, width: 24, height: 26)
                context.fill(Path(ellipseIn: leftEye), with: .color(.white))
                context.fill(Path(ellipseIn: rightEye), with: .color(.white))
                
                // Pupils
                let pupilY = isPoked ? center.y - 18 : center.y - 14
                context.fill(Path(ellipseIn: CGRect(x: center.x - 26, y: pupilY, width: 11, height: 11)), with: .color(.black))
                context.fill(Path(ellipseIn: CGRect(x: center.x + 15, y: pupilY, width: 11, height: 11)), with: .color(.black))
                // White sparkle
                context.fill(Path(ellipseIn: CGRect(x: center.x - 24, y: pupilY - 2, width: 4, height: 4)), with: .color(.white))
                context.fill(Path(ellipseIn: CGRect(x: center.x + 17, y: pupilY - 2, width: 4, height: 4)), with: .color(.white))
            }
            
            // 6. Mouth / Mandibles
            var mouthPath = Path()
            if isChewing {
                let chewRect = CGRect(x: center.x - 12, y: center.y + 12, width: 24, height: 16)
                context.fill(Path(ellipseIn: chewRect), with: .color(Color(red: 0.3, green: 0.1, blue: 0.1)))
            } else if beetle.hunger < 25 {
                // Sad / hangry
                mouthPath.move(to: CGPoint(x: center.x - 18, y: center.y + 22))
                mouthPath.addQuadCurve(to: CGPoint(x: center.x + 18, y: center.y + 22),
                                       control: CGPoint(x: center.x, y: center.y + 12))
                context.stroke(mouthPath, with: .color(.black), lineWidth: 4)
            } else {
                // Happy smile
                mouthPath.move(to: CGPoint(x: center.x - 18, y: center.y + 15))
                mouthPath.addQuadCurve(to: CGPoint(x: center.x + 18, y: center.y + 15),
                                       control: CGPoint(x: center.x, y: center.y + 27))
                context.stroke(mouthPath, with: .color(.black), lineWidth: 4)
            }
        }
        .frame(width: 220, height: 220)
        .scaleEffect(breathScale)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                breathScale = 1.04
                legWiggle = 6.0
            }
        }
    }
}
