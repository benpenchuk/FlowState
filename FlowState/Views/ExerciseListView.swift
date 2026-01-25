//
//  ExerciseListView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var showingAddExercise = false
    @State private var showingMoreFilters = false
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var selectedMuscleGroups: Set<MuscleGroupFilter> = []
    @State private var favoritesOnly: Bool = false
    @State private var customOnly: Bool = false
    @State private var editingExercise: Exercise? = nil
    
    private var secondaryActiveFilterCount: Int {
        selectedEquipment.count
        + (favoritesOnly ? 1 : 0)
        + (customOnly ? 1 : 0)
    }
    
    var filteredExercises: [Exercise] {
        // Single pipeline: search -> muscle -> equipment -> favorites/custom
        var exercises = viewModel.exercises
        
        let trimmedSearch = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(trimmedSearch) }
        }
        
        if !selectedMuscleGroups.isEmpty {
            let selectedCategories = Set(selectedMuscleGroups.map(\.title))
            exercises = exercises.filter { selectedCategories.contains($0.category) }
        }
        
        if !selectedEquipment.isEmpty {
            exercises = exercises.filter { exercise in
                !Set(exercise.equipment).isDisjoint(with: selectedEquipment)
            }
        }
        
        if favoritesOnly {
            exercises = exercises.filter { $0.isFavorite }
        }
        
        if customOnly {
            exercises = exercises.filter { $0.isCustom }
        }
        
        return exercises
    }
    
    var displayedExercises: [Exercise] {
        filteredExercises.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                skeletonList
            } else {
                exerciseList
            }
        }
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingMoreFilters) {
            MoreFiltersSheet(
                selectedEquipment: $selectedEquipment,
                favoritesOnly: $favoritesOnly,
                customOnly: $customOnly
            )
        }
        .sheet(item: $editingExercise) { exercise in
            EditExerciseSheet(viewModel: viewModel, exercise: exercise)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
    private var skeletonList: some View {
        List {
            ForEach(0..<10, id: \.self) { _ in
                SkeletonExerciseRow()
            }
        }
    }
    
    private var exerciseList: some View {
        List {
            ForEach(displayedExercises) { exercise in
                NavigationLink {
                    ExerciseDetailView(exercise: exercise)
                } label: {
                    ExerciseRowCard(exercise: exercise) {
                        viewModel.toggleFavorite(exercise)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        viewModel.toggleFavorite(exercise)
                    } label: {
                        Label(exercise.isFavorite ? "Unfavorite" : "Favorite", systemImage: exercise.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if exercise.isCustom {
                        Button {
                            editingExercise = exercise
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                        
                        Button(role: .destructive) {
                            viewModel.deleteCustomExercise(exercise)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
            ExerciseFilterBar(
                selectedMuscleGroups: $selectedMuscleGroups,
                secondaryActiveFilterCount: secondaryActiveFilterCount,
                onTapMoreFilters: { showingMoreFilters = true }
            )
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(Color(.systemBackground))
            .overlay(Divider(), alignment: .bottom)
        }
    }
}

struct MoreFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEquipment: Set<Equipment>
    @Binding var favoritesOnly: Bool
    @Binding var customOnly: Bool
    
    var availableEquipment: [Equipment] {
        [
            // Strength
            .barbell, .dumbbell, .cable, .machine, .bodyweight,
            .kettlebell, .resistanceBand, .ezBar, .trapBar, .smithMachine,
            .pullupBar, .dipBars, .bench, .inclineBench, .declineBench,
            // Cardio
            .treadmill, .bike, .rowingMachine, .elliptical, .stairClimber, .jumpRope, .none
        ]
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Equipment") {
                    ForEach(availableEquipment, id: \.self) { equipment in
                        Button {
                            if selectedEquipment.contains(equipment) {
                                selectedEquipment.remove(equipment)
                            } else {
                                selectedEquipment.insert(equipment)
                            }
                        } label: {
                            HStack {
                                Text(equipmentDisplayName(equipment))
                                Spacer()
                                if selectedEquipment.contains(equipment) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.flowStateOrange)
                                }
                            }
                        }
                    }
                }
                
                Section("Other") {
                    Toggle(isOn: $favoritesOnly) {
                        Label("Favorites", systemImage: favoritesOnly ? "star.fill" : "star")
                    }
                    
                    Toggle(isOn: $customOnly) {
                        Label("Custom", systemImage: customOnly ? "pencil.circle.fill" : "pencil.circle")
                    }
                }
            }
            .navigationTitle("More Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear") {
                        selectedEquipment.removeAll()
                        favoritesOnly = false
                        customOnly = false
                    }
                    .disabled(selectedEquipment.isEmpty && !favoritesOnly && !customOnly)
                }
            }
        }
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
}

#Preview {
    NavigationStack {
        ExerciseListView()
            .modelContainer(for: Exercise.self, inMemory: true)
    }
}
