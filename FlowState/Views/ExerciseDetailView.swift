//
//  ExerciseDetailView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @StateObject private var progressViewModel = ProgressViewModel()
    @StateObject private var libraryViewModel = ExerciseLibraryViewModel()
    @State private var currentPR: PersonalRecord? = nil
    @State private var progressionData: [(date: Date, weight: Double)] = []
    @State private var prs: [PersonalRecord] = []
    @State private var history: [(date: Date, maxWeight: Double, sets: [SetRecord])] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Exercise Header
                exerciseHeader
                
                // Equipment Section
                if !exercise.equipment.isEmpty {
                    equipmentSection
                }
                
                // Muscles Section (for strength exercises)
                if exercise.exerciseType == .strength && (!exercise.primaryMuscles.isEmpty || !exercise.secondaryMuscles.isEmpty) {
                    musclesSection
                }
                
                // Instructions Section
                if !exercise.instructions.setup.isEmpty || !exercise.instructions.execution.isEmpty || !exercise.instructions.tips.isEmpty {
                    instructionsSection
                }
                
                // PR Section
                prSection
                
                // Progress Chart
                progressChartSection
                
                // Recent History
                historySection
            }
            .padding()
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    libraryViewModel.toggleFavorite(exercise)
                } label: {
                    Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(exercise.isFavorite ? .yellow : .primary)
                }
            }
        }
        .onAppear {
            progressViewModel.setModelContext(modelContext)
            libraryViewModel.setModelContext(modelContext)
            loadData()
        }
    }
    
    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(exercise.category, systemImage: "tag.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if exercise.isCustom {
                    Label("Custom", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                Text("Equipment")
                    .font(.headline)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(exercise.equipment, id: \.self) { equipment in
                    Text(equipmentDisplayName(equipment))
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBlue).opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                Text("Muscles Worked")
                    .font(.headline)
            }
            
            if !exercise.primaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Primary")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGreen).opacity(0.2))
                                .foregroundStyle(.green)
                                .cornerRadius(16)
                        }
                    }
                }
            }
            
            if !exercise.secondaryMuscles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Secondary")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemOrange).opacity(0.2))
                                .foregroundStyle(.orange)
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "book.fill")
                Text("Instructions")
                    .font(.headline)
            }
            
            if !exercise.instructions.setup.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(exercise.instructions.setup)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !exercise.instructions.execution.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Execution")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(exercise.instructions.execution)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !exercise.instructions.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(exercise.instructions.tips)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func equipmentDisplayName(_ equipment: Equipment) -> String {
        switch equipment {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .resistanceBand: return "Resistance Band"
        case .ezBar: return "EZ Bar"
        case .trapBar: return "Trap Bar"
        case .smithMachine: return "Smith Machine"
        case .pullupBar: return "Pull-up Bar"
        case .dipBars: return "Dip Bars"
        case .bench: return "Bench"
        case .inclineBench: return "Incline Bench"
        case .declineBench: return "Decline Bench"
        case .treadmill: return "Treadmill"
        case .bike: return "Bike"
        case .rowingMachine: return "Rowing Machine"
        case .elliptical: return "Elliptical"
        case .stairClimber: return "Stair Climber"
        case .jumpRope: return "Jump Rope"
        case .none: return "None"
        }
    }
    
    private var prSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Personal Record")
                    .font(.headline)
            }
            
            if let pr = currentPR {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(String(format: "%.1f", pr.weight)) lbs")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("× \(pr.reps) reps")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatDate(pr.achievedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let daysAgo = daysSince(pr.achievedAt) {
                            Text("\(daysAgo) days ago")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Text("No personal record yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Progress")
                    .font(.headline)
            }
            
            ExerciseProgressChartView(
                progressionData: progressionData,
                prs: prs
            )
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                Text("Recent History")
                    .font(.headline)
            }
            
            if history.isEmpty {
                Text("No workout history yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(Array(history.enumerated()), id: \.offset) { index, entry in
                    HistoryRowView(
                        date: entry.date,
                        maxWeight: entry.maxWeight,
                        sets: entry.sets
                    )
                }
            }
        }
    }
    
    private func loadData() {
        currentPR = progressViewModel.calculatePR(for: exercise)
        progressionData = progressViewModel.getWeightProgression(for: exercise)
        
        // Get all PRs for this exercise for chart highlighting - fetch all and filter in memory
        let descriptor = FetchDescriptor<PersonalRecord>(
            sortBy: [SortDescriptor(\.achievedAt, order: .reverse)]
        )
        
        do {
            let allPRs = try modelContext.fetch(descriptor)
            prs = allPRs.filter { $0.exercise?.id == exercise.id }
        } catch {
            print("Error fetching PRs: \(error)")
            prs = []
        }
        
        history = progressViewModel.getExerciseHistory(for: exercise, limit: 10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func daysSince(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        return components.day
    }
}

struct HistoryRowView: View {
    let date: Date
    let maxWeight: Double
    let sets: [SetRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(String(format: "%.1f", maxWeight)) lbs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 4) {
                ForEach(sets) { set in
                    if let weight = set.weight, let reps = set.reps {
                        Text("\(String(format: "%.1f", weight))×\(reps)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// FlowLayout helper for wrapping tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(
            exercise: Exercise(
                name: "Bench Press",
                exerciseType: .strength,
                category: "Chest",
                equipment: [.barbell, .bench],
                primaryMuscles: ["Chest", "Triceps"],
                secondaryMuscles: ["Shoulders"]
            )
        )
        .modelContainer(for: [Exercise.self, PersonalRecord.self, Workout.self], inMemory: true)
    }
}
