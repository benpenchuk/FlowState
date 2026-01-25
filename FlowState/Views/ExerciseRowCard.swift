//
//  ExerciseRowCard.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/25/26.
//

import SwiftUI

struct ExerciseRowCard: View {
    let exercise: Exercise
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggleFavorite) {
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(exercise.isFavorite ? .yellow : .secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Spacer(minLength: 0)
                    
                    if exercise.isCustom {
                        Text("Custom")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.flowStateOrange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.flowStateOrange.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 8) {
                    Label(exercise.category, systemImage: categorySymbolName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                }
                
                if !exercise.equipment.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(exercise.equipment.prefix(4), id: \.self) { equipment in
                            Text(equipmentShortName(equipment))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                        if exercise.equipment.count > 4 {
                            Text("+\(exercise.equipment.count - 4)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    private var categorySymbolName: String {
        switch exercise.exerciseType {
        case .strength:
            return "figure.strengthtraining.traditional"
        case .cardio:
            return "figure.run"
        }
    }
    
    private func equipmentShortName(_ equipment: Equipment) -> String {
        switch equipment {
        case .barbell: return "BB"
        case .dumbbell: return "DB"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyweight: return "BW"
        case .kettlebell: return "KB"
        case .resistanceBand: return "Band"
        case .ezBar: return "EZ"
        case .trapBar: return "Trap"
        case .smithMachine: return "Smith"
        case .pullupBar: return "Bar"
        case .dipBars: return "Dips"
        case .bench: return "Bench"
        case .inclineBench: return "Incline"
        case .declineBench: return "Decline"
        case .treadmill: return "Treadmill"
        case .bike: return "Bike"
        case .rowingMachine: return "Rower"
        case .elliptical: return "Elliptical"
        case .stairClimber: return "Stairs"
        case .jumpRope: return "Rope"
        case .none: return "None"
        }
    }
}

#Preview {
    ExerciseRowCard(
        exercise: Exercise(
            name: "Barbell Bench Press",
            exerciseType: .strength,
            category: "Chest",
            equipment: [.barbell, .bench],
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            isCustom: false,
            isFavorite: true
        ),
        onToggleFavorite: {}
    )
    .padding()
}

