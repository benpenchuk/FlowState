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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Section
                    statsSection
                    
                    // Recent Achievements Section
                    recentAchievementsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
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
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            if isEditingName {
                TextField("Name", text: $editedName)
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        viewModel.updateName(editedName)
                        isEditingName = false
                    }
                    .onAppear {
                        editedName = viewModel.profile?.name ?? "Athlete"
                    }
            } else {
                Text(viewModel.profile?.name ?? "Athlete")
                    .font(.system(size: 32, weight: .bold))
                    .onTapGesture {
                        isEditingName = true
                    }
            }
            
            if let createdAt = viewModel.profile?.createdAt {
                Text("Member since \(formatDate(createdAt))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats")
                .font(.headline)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "figure.walk",
                    value: "\(viewModel.totalWorkouts)",
                    label: "Workouts"
                )
                
                StatCard(
                    icon: "star.fill",
                    value: "\(viewModel.totalPRs)",
                    label: "PRs"
                )
                
                StatCard(
                    icon: "flame.fill",
                    value: "\(viewModel.currentStreak)",
                    label: "Day Streak"
                )
            }
        }
    }
    
    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Achievements")
                .font(.headline)
                .padding(.horizontal, 4)
            
            if viewModel.recentPRs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No recent PRs yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Complete workouts to start tracking your progress!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                ForEach(viewModel.recentPRs) { pr in
                    PRCard(
                        pr: pr,
                        preferredUnits: viewModel.profile?.units ?? .lbs
                    )
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
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
                .font(.title3)
                .foregroundStyle(.yellow)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exercise?.name ?? "Unknown Exercise")
                    .font(.headline)
                
                Text(formatPR(pr))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formatDate(pr.achievedAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatPR(_ pr: PersonalRecord) -> String {
        let weight = pr.weight
        let displayWeight = preferredUnits == .kg ? weight / 2.20462 : weight
        let unit = preferredUnits == .kg ? "kg" : "lbs"
        
        return "\(String(format: "%.1f", displayWeight)) \(unit) × \(pr.reps) reps"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Workout.self, PersonalRecord.self], inMemory: true)
}
