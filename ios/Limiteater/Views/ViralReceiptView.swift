//
//  ViralReceiptView.swift
//  Limiteater
//  Meme invoice generator from Anthropic/OpenAI for social media sharing
//

import SwiftUI
import UIKit

public struct ViralReceiptView: View {
    @Environment(\.presentationMode) var presentationMode
    public var beetle: Beetle
    
    public var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.14).ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button("Закрыть") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                .padding()
                
                Text("🧾 ШТРАФНОЙ СЧЁТ")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                // Invoice Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("INVOICE #AI-429-HOTFIX")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                        Spacer()
                        Text("ОПЛАЧЕНО НЕРВАМИ")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.red)
                            .padding(4)
                            .border(Color.red, width: 2)
                            .rotationEffect(.degrees(-8))
                    }
                    
                    Text("---------------------------------")
                        .foregroundColor(.gray)
                    
                    Text("Клиент: Владелец жука \"\(beetle.name)\"")
                        .font(.system(size: 12, design: .monospaced))
                    Text("Виновник: Жук-Лимитоед (Режим обжорства)")
                        .font(.system(size: 12, design: .monospaced))
                    
                    Text("---------------------------------")
                        .foregroundColor(.gray)
                    
                    Text("• Промпты в цикле while(true): 1,420 токенов")
                        .font(.system(size: 11, design: .monospaced))
                    Text("• Случайно отправленный node_modules: 8,900,120")
                        .font(.system(size: 11, design: .monospaced))
                    Text("• Баги сеньора, выданные за фичу: Бесценно")
                        .font(.system(size: 11, design: .monospaced))
                    
                    Text("---------------------------------")
                        .foregroundColor(.gray)
                    
                    Text("ИТОГО К ОПЛАТЕ: $420.69 USD")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                    
                    Text("Лимиты обнулятся через 3 часа. Учите синтаксис!")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(16)
                .shadow(radius: 12)
                .padding(.horizontal)
                
                // Share Button
                Button(action: shareInvoice) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Поделиться позором в Telegram / Stories")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(18)
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private func shareInvoice() {
        let text = "🚨 МОЙ ЖУК-ЛИМИТОЕД '\(beetle.name)' ТОЛЬКО ЧТО СОЖРАЛ ТОКЕНОВ НА $420.69!\nВыписан штраф от Anthropic. До сброса лимитов 3 часа 💀 #ЖукЛимитоед #AI"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }
}
