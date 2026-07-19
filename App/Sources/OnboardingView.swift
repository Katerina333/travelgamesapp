import SwiftUI
import SwiftData
import CoreKit
import GameEngine
import TripKit

/// Trip-creation flow (§2.1): travel type → travelers + driver → length →
/// destination → generate board. Scheduling and the paywall step land in
/// later Stage 1 feature branches.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let onCreated: (Trip) -> Void

    @State private var mode: TravelMode = .car
    @State private var length: TripLength = .medium
    @State private var destination = ""
    @State private var drafts: [TravelerDraft] = []
    @State private var showAdd = false

    struct TravelerDraft: Identifiable {
        let id = UUID()
        var name: String
        var age: Int
        var isDriver: Bool
    }

    private var driverCount: Int { drafts.filter(\.isDriver).count }

    /// Car trips require exactly one driver (§2.1); planes have none (§1.4).
    private var canCreate: Bool {
        !drafts.isEmpty && (mode == .plane || driverCount == 1)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("onboarding.travelType") {
                    Picker("onboarding.travelType", selection: $mode) {
                        Text("onboarding.travelType.car").tag(TravelMode.car)
                        Text("onboarding.travelType.plane").tag(TravelMode.plane)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("picker.travelType")
                }

                Section("onboarding.travelers") {
                    ForEach(drafts) { draft in
                        HStack {
                            Text(verbatim: draft.name)
                            Spacer()
                            Text(verbatim: "\(draft.age)")
                                .foregroundStyle(.secondary)
                            if draft.isDriver && mode == .car {
                                Image(systemName: "steeringwheel")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { drafts.remove(atOffsets: $0) }

                    Button("onboarding.addTraveler") { showAdd = true }
                        .accessibilityIdentifier("btn.addTraveler")
                }

                Section("onboarding.length") {
                    Picker("onboarding.length", selection: $length) {
                        Text("onboarding.length.short").tag(TripLength.short)
                        Text("onboarding.length.medium").tag(TripLength.medium)
                        Text("onboarding.length.long").tag(TripLength.long)
                    }
                    .pickerStyle(.segmented)
                }

                Section("onboarding.destination") {
                    TextField("onboarding.destination.placeholder", text: $destination)
                        .accessibilityIdentifier("field.destination")
                }

                Section {
                    Button("onboarding.createTrip", action: createTrip)
                        .disabled(!canCreate)
                        .accessibilityIdentifier("btn.createTrip")
                }
            }
            .navigationTitle("onboarding.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTravelerSheet(mode: mode, defaultName: "Player \(drafts.count + 1)") { draft in
                    if draft.isDriver {
                        for index in drafts.indices { drafts[index].isDriver = false }
                    }
                    drafts.append(draft)
                }
            }
        }
    }

    private func createTrip() {
        let avatars = ["face.smiling", "star.fill", "heart.fill", "bolt.fill", "leaf.fill", "pawprint.fill"]
        let travelers = drafts.enumerated().map { index, draft in
            Traveler(
                name: draft.name,
                avatar: avatars[index % avatars.count],
                age: draft.age,
                isDriver: mode == .car && draft.isDriver
            )
        }
        let trip = TripBuilder.makeTrip(
            travelers: travelers,
            mode: mode,
            length: length,
            destinationName: destination.isEmpty ? nil : destination,
            manifests: GameRegistry.shared.allManifests
        )
        context.insert(trip)
        try? context.save()
        onCreated(trip)
    }
}

struct AddTravelerSheet: View {
    let mode: TravelMode
    let defaultName: String
    let onSave: (OnboardingView.TravelerDraft) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var age = 8
    @State private var isDriver = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("onboarding.traveler.name", text: $name, prompt: Text(verbatim: defaultName))
                    .accessibilityIdentifier("field.travelerName")

                Picker("onboarding.traveler.age", selection: $age) {
                    ForEach(1..<100, id: \.self) { value in
                        Text(verbatim: "\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .accessibilityIdentifier("picker.age")

                if mode == .car {
                    Toggle("onboarding.traveler.driver", isOn: $isDriver)
                        .accessibilityIdentifier("toggle.driver")
                }
            }
            .navigationTitle("onboarding.addTraveler")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        onSave(OnboardingView.TravelerDraft(
                            name: trimmed.isEmpty ? defaultName : trimmed,
                            age: age,
                            isDriver: mode == .car && isDriver
                        ))
                        dismiss()
                    }
                    .accessibilityIdentifier("btn.saveTraveler")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
