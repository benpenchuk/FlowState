//
//  ExerciseFilterBar.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/25/26.
//

import SwiftUI

struct ExerciseFilterBar: View {
    @Binding var selectedMuscleGroups: Set<MuscleGroupFilter>
    let secondaryActiveFilterCount: Int
    let onTapMoreFilters: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(MuscleGroupFilter.allCases) { group in
                    FilterChip(
                        title: group.title,
                        systemImage: group.symbolName,
                        isSelected: selectedMuscleGroups.contains(group)
                    ) {
                        if selectedMuscleGroups.contains(group) {
                            selectedMuscleGroups.remove(group)
                        } else {
                            selectedMuscleGroups.insert(group)
                        }
                    }
                }
                
                FilterChip(
                    title: secondaryActiveFilterCount == 0 ? "More Filters" : "More Filters (\(secondaryActiveFilterCount))",
                    systemImage: "line.3.horizontal.decrease.circle",
                    isSelected: false
                ) {
                    onTapMoreFilters()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(isSelected ? Color.flowStateOrange : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(Color(.systemGray5), lineWidth: isSelected ? 0 : 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 0) {
        ExerciseFilterBar(
            selectedMuscleGroups: .constant([]),
            secondaryActiveFilterCount: 0,
            onTapMoreFilters: {}
        )
        Spacer()
    }
}

