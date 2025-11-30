//
//  Prez_Action_View.swift
//  Society Game
//
//  Created by Jeffrey Zheng on 11/22/25.
//
import SwiftUI

struct PresidentialActionsView: View {
    @ObservedObject var game: GameState
    @Environment(\.dismiss) private var dismiss

    @State private var speechText: String = ""
    @State private var selectedProjectID: GovernmentProject.ID? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.90),
                        Color(red: 0.95, green: 0.92, blue: 0.84)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - President's Speech
                        GroupBox {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("🎙️ President's Speech (2g)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                    Spacer()
                                }

                                Text("Broadcast a cheaper rally only the President can make.")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)

                                TextField("Write your speech…", text: $speechText, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...4)

                                HStack {
                                    Spacer()
                                    Button {
                                        sendPresidentSpeech()
                                    } label: {
                                        Text("Send Speech (−2 gold)")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    .disabled(!canSendSpeech)
                                }
                            }
                            .padding(8)
                        }

                        // MARK: - Executive Order (just navigation now)
                        GroupBox {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("📜 Executive Order (5g)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))

                                Text("Enforce a government project on any department. Configure details in the Executive Orders screen.")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)

                                NavigationLink {
                                    ExecutiveOrdersView(game: game)
                                } label: {
                                    Text("Explore Executive Orders")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            LinearGradient(
                                                colors: [Color.orange, Color(red: 0.95, green: 0.65, blue: 0.25)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(8)
                        }

                        // MARK: - Veto Power
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("🛑 Veto Power")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))

                                Text("Block a current government project. SCCJ can later attempt a Judicial Override.")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)

                                if game.vetoableProjects.isEmpty {
                                    Text("No active government projects to veto right now.")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 4)
                                } else {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Choose a project to veto:")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))

                                        Picker("Project", selection: $selectedProjectID) {
                                            Text("Select a project…")
                                                .tag(Optional<UUID>.none)

                                            ForEach(game.vetoableProjects) { project in
                                                HStack {
                                                    Text(project.name)
                                                    Text("(\(project.department.rawValue))")
                                                        .foregroundColor(.secondary)
                                                }
                                                .tag(Optional<UUID>.some(project.id))
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }

                                    HStack {
                                        Spacer()
                                        Button {
                                            useVeto()
                                        } label: {
                                            Text("Use Veto")
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 9)
                                                .background(Color.red)
                                                .foregroundColor(.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        .disabled(selectedProjectID == nil)
                                    }
                                }
                            }
                            .padding(8)
                        }

                        Spacer(minLength: 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Presidential Actions")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back to Game") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var canSendSpeech: Bool {
        !speechText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && game.canAfford(2)
    }

    private func sendPresidentSpeech() {
        guard canSendSpeech else { return }
        // use the same rally mechanic but cost 2g, tagged as "presidential"
        game.spend(2)
        game.messages.append(
            ChatMessage(
                fromIndex: game.currentIndex,
                toIndex: nil,
                text: "[PRESIDENT'S SPEECH] \(speechText)",
                isRally: true,
                round: game.campaignRound   // or turnNumber if we're in running stage
            )
        )
        speechText = ""
    }

    private func useVeto() {
        guard let id = selectedProjectID else { return }
        game.applyPresidentialVeto(to: id)
        selectedProjectID = nil
    }
}
