//
//  MultiPetSheetView.swift
//  Limiteater
//  Multi-Beetle Incubator & Selector
//

import SwiftUI

public struct MultiPetSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentBeetle: Beetle
    
    @State private var newName: String = ""
    @State private var beetles: [Beetle] = [
        Beetle(name: "Клодик"),
        Beetle(name: "Кёрсорик", level: 2, hunger: 50, toilet: 40, clean: 90, energy: 60, tokensEaten: 4200),
        Beetle(name: "Олламыч", level: 3, hunger: 90, toilet: 95, clean: 40, energy: 30, tokensEaten: 9800)
    ]
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.14).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Выращивай сразу нескольких лимитоедов!")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    List {
                        ForEach(beetles) { pet in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🪲 \(pet.name)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Lvl \(pet.level) • Сожрал: \(pet.tokensEaten) токенов")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if currentBeetle.name == pet.name {
                                    Text("Активен")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.green)
                                } else {
                                    Button("Выбрать") {
                                        currentBeetle = pet
                                        SharedDataManager.shared.saveBeetle(pet)
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            .listRowBackground(Color(red: 0.14, green: 0.16, blue: 0.24))
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    
                    HStack {
                        TextField("Имя нового жука...", text: $newName)
                            .padding(10)
                            .background(Color(red: 0.14, green: 0.16, blue: 0.24))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        Button("Вывести") {
                            guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let newPet = Beetle(name: newName)
                            beetles.append(newPet)
                            currentBeetle = newPet
                            SharedDataManager.shared.saveBeetle(newPet)
                            newName = ""
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .font(.headline)
                    }
                    .padding()
                }
            }
            .navigationTitle("Выбор Жука")
            .navigationBarItems(trailing: Button("Готово") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
