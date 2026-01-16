//
//  WorkoutCompletionView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct WorkoutCompletionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workout: Workout
    let duration: TimeInterval
    let exerciseCount: Int
    let completedSetCount: Int
    let prCount: Int
    let onSave: (Int?, String?) -> Void
    
    @State private var selectedEffort: Int? = nil
    @State private var notes: String = ""
    @State private var checkmarkScale: CGFloat = 0.5
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Celebration Section
                celebrationSection
                
                // Stats Row
                statsRow
                    .padding(.top, 12)
                
                Spacer()
                    .frame(height: 8)
                
                // Effort Scale Section
                effortScaleSection
                
                // Selected effort display (if any)
                if selectedEffort != nil {
                    Spacer()
                        .frame(height: 8)
                } else {
                    Spacer()
                        .frame(height: 12)
                }
                
                // Notes Field
                notesField
                
                Spacer()
                
                // Done Button
                doneButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    EmptyView()
                }
            }
        }
        .onAppear {
            // Animate checkmark on appear
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                checkmarkScale = 1.0
            }
        }
    }
    
    // MARK: - Celebration Section
    
    private var celebrationSection: some View {
        VStack(spacing: 8) {
            // Large checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 65))
                .foregroundStyle(Color.accentColor)
                .scaleEffect(checkmarkScale)
            
            // Title
            Text("Workout Complete!")
                .font(.title2)
                .fontWeight(.bold)
            
            // Workout name
            if let name = workout.name, !name.isEmpty {
                Text(name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            
            // Duration
            Text(formatDuration(duration))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            StatItem(value: "\(exerciseCount)", label: "Exercises", icon: "dumbbell")
            
            StatItem(value: "\(completedSetCount)", label: "Sets", icon: "checkmark.circle")
            
            StatItem(
                value: "\(prCount)",
                label: "PRs",
                icon: "star.fill",
                isHighlighted: prCount > 0
            )
        }
    }
    
    // MARK: - Effort Scale Section
    
    private var effortScaleSection: some View {
        VStack(spacing: 16) {
            Text("How did it feel?")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Bar Chart Scale
            VStack(spacing: 12) {
                // Bars
                HStack(alignment: .bottom, spacing: 1) {
                    ForEach(1...10, id: \.self) { number in
                        EffortBar(
                            number: number,
                            selectedEffort: selectedEffort,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedEffort = selectedEffort == number ? nil : number
                                }
                            }
                        )
                    }
                }
                .frame(height: 120)
                
                // Labels
                HStack {
                    Text("Easy")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("All Out")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Selected effort display
                if let effort = selectedEffort {
                    Text("Effort: \(effort)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Notes Field
    
    private var notesField: some View {
        TextField("Add notes (optional)", text: $notes, axis: .vertical)
            .lineLimit(1...2)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(height: 48)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        Button {
            onSave(selectedEffort, notes.isEmpty ? nil : notes)
            dismiss()
        } label: {
            Text("Done")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes) min"
        }
    }
}

// MARK: - Effort Bar View

struct EffortBar: View {
    let number: Int
    let selectedEffort: Int?
    let onTap: () -> Void
    
    private var isSelected: Bool {
        selectedEffort != nil && number <= selectedEffort!
    }
    
    // Bar height increases progressively (staircase effect)
    // Tallest bar (10) should be around 100pt
    private var barHeight: CGFloat {
        let baseHeight: CGFloat = 20
        let increment: CGFloat = 9
        return baseHeight + (CGFloat(number - 1) * increment)
    }
    
    private var barColor: Color {
        guard let selectedEffort = selectedEffort else {
            return Color(.systemGray4)
        }
        
        // All selected bars use the color based on the selected effort level
        switch selectedEffort {
        case 1...3:
            return .green
        case 4...6:
            return .orange
        case 7...8:
            return .red
        case 9...10:
            return Color(red: 0.6, green: 0.0, blue: 0.6) // Purple
        default:
            return Color(.systemGray4)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Bar container with tap target
            Button(action: onTap) {
                ZStack(alignment: .bottom) {
                    // Background (unselected state)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray4))
                        .frame(width: 26, height: barHeight)
                    
                    // Filled portion (selected state) - animates from bottom
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(width: 26, height: isSelected ? barHeight : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: barHeight + 20) // Tap target area
            .contentShape(Rectangle())
            
            // Number label
            Text("\(number)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 26)
        }
    }
}

// MARK: - Stat Item View

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isHighlighted ? .yellow : Color.accentColor)
                
                if isHighlighted {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    WorkoutCompletionView(
        workout: Workout(name: "Push Day", startedAt: Date().addingTimeInterval(-1920), completedAt: Date()),
        duration: 1920, // 32 minutes
        exerciseCount: 5,
        completedSetCount: 15,
        prCount: 2,
        onSave: { _, _ in }
    )
    .modelContainer(for: [Workout.self], inMemory: true)
}
