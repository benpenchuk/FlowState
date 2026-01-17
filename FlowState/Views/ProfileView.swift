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
                VStack(spacing: 32) {
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
            
            if viewModel.isLoading {
                SkeletonStatsCard()
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        StatCard(icon: "figure.walk", value: "\(viewModel.totalWorkouts)", label: "Workouts")
                        StatCard(icon: "star.fill", value: "\(viewModel.totalPRs)", label: "PRs")
                    }
                    HStack(spacing: 8) {
                        StatCard(icon: "flame.fill", value: "\(viewModel.currentStreak)", label: "Streak")
                        StatCard(icon: "scalemass", value: formatTotalVolume(viewModel.totalVolume), label: "Volume")
                    }
                }
            }
        }
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
    
    private func formatTotalVolume(_ volumeInLbs: Double) -> String {
        let preferredUnits = viewModel.profile?.units ?? .lbs
        let displayVolume = preferredUnits == .kg ? volumeInLbs / 2.20462 : volumeInLbs
        let unitLabel = preferredUnits == .kg ? "kg" : "lbs"
        
        // Use abbreviated formatting for large numbers (e.g., 24k, 2.1M)
        let abbreviated = displayVolume.abbreviated()
        return "\(abbreviated) \(unitLabel)"
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
