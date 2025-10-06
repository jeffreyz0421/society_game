//
//  Society_Game_Running_Phase.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 9/28/25.
//

import SwiftUI

// MARK: - Running Stage (Society Management & Turn Flow)

struct SocietyPanel: View {
    @ObservedObject var game: GameState

    var body: some View {
        VStack(spacing: 8) {
            Text("Society Counters (simplified)")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                gridRow(title: "Population",
                        get: game.society.population,
                        plus: { game.addPopulation(1) },
                        minus: { game.addPopulation(-1) })

                gridRow(title: "Uneducated",
                        get: game.society.uneducated,
                        plus: { game.addUneducated(1) },
                        minus: { game.addUneducated(-1) })

                gridRow(title: "Educated",
                        get: game.society.educated,
                        plus: { game.addEducated(1) },
                        minus: { game.addEducated(-1) })

                gridRow(title: "High-Skilled",
                        get: game.society.highSkilled,
                        plus: { game.addHighSkilled(1) },
                        minus: { game.addHighSkilled(-1) })

                gridRow(title: "Researchers",
                        get: game.society.researchers,
                        plus: { game.addResearchers(1) },
                        minus: { game.addResearchers(-1) })

                gridRow(title: "Small Buildings",
                        get: game.society.smallBuildings,
                        plus: { game.addSmallBuilding(1) },
                        minus: { game.addSmallBuilding(-1) })

                gridRow(title: "Big Buildings",
                        get: game.society.bigBuildings,
                        plus: { game.addBigBuilding(1) },
                        minus: { game.addBigBuilding(-1) })

                gridRow(title: "Machinery",
                        get: game.society.machinery,
                        plus: { game.addMachinery(1) },
                        minus: { game.addMachinery(-1) })
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack {
                Text("Current Society Points: \(game.society.totalSocietyPoints())")
                    .bold()
                Spacer()
            }
        }
    }

    // MARK: - Helper Row Builder
    @ViewBuilder
    private func gridRow(title: String, get: Int,
                         plus: @escaping () -> Void,
                         minus: @escaping () -> Void) -> some View {
        GridRow {
            Text(title)
            Text("\(get)").monospacedDigit()
            HStack {
                Button("+", action: plus)
                Button("−", action: minus)
            }
        }
    }
}
