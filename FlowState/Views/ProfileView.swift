//
//  ProfileView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingClearDataAlert = false
    @State private var showingAboutAlert = false
    @State private var isPreferencesExpanded = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Section
                    statsSection
                    
                    // Recent Achievements Section
                    recentAchievementsSection
                    
                    // Preferences Section
                    preferencesSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(\.modelContext, modelContext)
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { clearAllData() }
            } message: {
                Text("This will permanently delete all workouts, exercises, templates, and PRs. This cannot be undone.")
            }
            .alert("About FlowState", isPresented: $showingAboutAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("FlowState is a minimal workout tracker built with SwiftUI and SwiftData.")
            }
        }
    }
    
    private var initials: String {
        let name = viewModel.profile?.name ?? "Athlete"
        let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if parts.count > 1, let first = parts.first?.prefix(1), let last = parts.last?.prefix(1) {
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                Text(initials)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(Circle().stroke(Color.secondary.opacity(0.1), lineWidth: 1))
            
            VStack(spacing: 4) {
                if isEditingName {
                    TextField("Name", text: $editedName)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            viewModel.updateName(editedName)
                            isEditingName = false
                        }
                        .onAppear { editedName = viewModel.profile?.name ?? "Athlete" }
                } else {
                    Text(viewModel.profile?.name ?? "Athlete")
                        .font(.title2.bold())
                        .onTapGesture { isEditingName = true }
                }
                
                if let createdAt = viewModel.profile?.createdAt {
                    Text("Member since \(formatDate(createdAt))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.headline)
            
            HStack(spacing: 8) {
                StatCard(icon: "figure.walk", value: "\(viewModel.totalWorkouts)", label: "Workouts")
                StatCard(icon: "star.fill", value: "\(viewModel.totalPRs)", label: "PRs")
                StatCard(icon: "flame.fill", value: "\(viewModel.currentStreak)", label: "Streak")
            }
        }
    }
    
    private var preferencesSection: some View {
        DisclosureGroup("Preferences", isExpanded: $isPreferencesExpanded) {
            VStack(spacing: 0) {
                if let profile = viewModel.profile {
                    preferenceRow("Units") {
                        Picker("Units", selection: Binding(get: { profile.units }, set: { viewModel.updatePreferredUnits($0) })) {
                            ForEach(Units.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                        }
                    }
                    Divider()
                    preferenceRow("Rest Time") {
                        Picker("Rest Time", selection: Binding(get: { profile.defaultRestTime }, set: { viewModel.updateDefaultRestTime($0) })) {
                            ForEach([30, 60, 90, 120, 180], id: \.self) { Text("\($0)s").tag($0) }
                        }
                    }
                    Divider()
                    preferenceRow("Appearance") {
                        Picker("Appearance", selection: Binding(get: { profile.appearance }, set: { viewModel.updateAppearanceMode($0) })) {
                            Text("Dark").tag(AppearanceMode.dark)
                            Text("Light").tag(AppearanceMode.light)
                            Text("System").tag(AppearanceMode.system)
                        }
                    }
                    Divider()
                    Button { showingAboutAlert = true } label: {
                        preferenceRow("About FlowState") { Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary) }
                    }.buttonStyle(.plain)
                    Divider()
                    Button(role: .destructive) { showingClearDataAlert = true } label: {
                        HStack { Text("Clear All Data"); Spacer() }.padding(.vertical, 12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .accentColor(.orange)
    }
    
    private func preferenceRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
            Spacer()
            content()
        }
        .padding(.vertical, 12)
    }
    
    private func clearAllData() {
        try? modelContext.delete(model: Workout.self)
        try? modelContext.delete(model: Exercise.self)
        try? modelContext.delete(model: WorkoutTemplate.self)
        try? modelContext.delete(model: PersonalRecord.self)
        try? modelContext.save()
        viewModel.refreshStats()
    }
    
    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
            
            if viewModel.recentPRs.isEmpty {
                Text("No recent PRs yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(viewModel.recentPRs) { pr in
                    PRCard(pr: pr, preferredUnits: viewModel.profile?.units ?? .lbs)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date, short: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = short ? .short : .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.orange)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PRCard: View {
    let pr: PersonalRecord
    let preferredUnits: Units
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exercise?.name ?? "Exercise").font(.subheadline).bold()
                Text(formatPR(pr)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(pr.achievedAt, style: .date).font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatPR(_ pr: PersonalRecord) -> String {
        let weight = pr.weight
        let displayWeight = preferredUnits == .kg ? weight / 2.20462 : weight
        return "\(String(format: "%.1f", displayWeight)) \(preferredUnits == .kg ? "kg" : "lbs") × \(pr.reps)"
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Workout.self, PersonalRecord.self], inMemory: true)
}
