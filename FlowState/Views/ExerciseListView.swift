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
    @State private var selectedExerciseType: ExerciseType = .strength
    @State private var showingEquipmentFilter = false
    @State private var selectedEquipment: Set<Equipment> = []
    
    // Strength categories
    private let strengthCategories = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]
    
    // Cardio categories
    private let cardioCategories = ["Running", "Cycling", "Rowing", "Stair Climber", "Jump Rope", "Swimming", "Walking", "HIIT"]
    
    var filteredExercises: [Exercise] {
        var exercises = viewModel.filteredExercises.filter { $0.exerciseType == selectedExerciseType }
        
        // Filter by equipment if any selected
        if !selectedEquipment.isEmpty {
            exercises = exercises.filter { exercise in
                !Set(exercise.equipment).isDisjoint(with: selectedEquipment)
            }
        }
        
        return exercises
    }
    
    var favoriteExercises: [Exercise] {
        filteredExercises.filter { $0.isFavorite }
    }
    
    var exercisesByCategory: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises.filter { !$0.isFavorite }) { $0.category }
    }
    
    var sortedCategories: [String] {
        let categories = selectedExerciseType == .strength ? strengthCategories : cardioCategories
        return categories.filter { exercisesByCategory[$0] != nil && !exercisesByCategory[$0]!.isEmpty }
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
        .searchable(text: $viewModel.searchText, prompt: "Search exercises")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEquipmentFilter.toggle()
                } label: {
                    Image(systemName: selectedEquipment.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .foregroundStyle(selectedEquipment.isEmpty ? .primary : Color.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingEquipmentFilter) {
            EquipmentFilterSheet(selectedEquipment: $selectedEquipment, exerciseType: selectedExerciseType)
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
            // Favorites section
            if !favoriteExercises.isEmpty {
                Section {
                    ForEach(favoriteExercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRowView(exercise: exercise, viewModel: viewModel)
                        }
                    }
                } header: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("Favorites")
                    }
                }
            }
            
            // Exercises by category
            ForEach(sortedCategories, id: \.self) { category in
                if let exercises = exercisesByCategory[category], !exercises.isEmpty {
                    Section {
                        let defaultExercises = exercises.filter { !$0.isCustom }
                        let customExercises = exercises.filter { $0.isCustom }
                        
                        ForEach(defaultExercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseRowView(exercise: exercise, viewModel: viewModel)
                            }
                        }
                        
                        ForEach(customExercises) { exercise in
                            NavigationLink {
                                ExerciseDetailView(exercise: exercise)
                            } label: {
                                ExerciseRowView(exercise: exercise, viewModel: viewModel)
                            }
                        }
                        .onDelete { indexSet in
                            deleteExercises(at: indexSet, in: customExercises)
                        }
                    } header: {
                        Text(category)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            Picker("Exercise Type", selection: $selectedExerciseType) {
                Text("Strength").tag(ExerciseType.strength)
                Text("Cardio").tag(ExerciseType.cardio)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    private func deleteExercises(at offsets: IndexSet, in exercises: [Exercise]) {
        for index in offsets {
            let exercise = exercises[index]
            viewModel.deleteCustomExercise(exercise)
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    @ObservedObject var viewModel: ExerciseLibraryViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Favorite button
            Button {
                toggleFavorite()
            } label: {
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(exercise.isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.body)
                
                // Equipment tags
                if !exercise.equipment.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(exercise.equipment.prefix(3), id: \.self) { equipment in
                            Text(equipmentDisplayName(equipment))
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                        if exercise.equipment.count > 3 {
                            Text("+\(exercise.equipment.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            if exercise.isCustom {
                Label("Custom", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func toggleFavorite() {
        viewModel.toggleFavorite(exercise)
    }
    
    private func equipmentDisplayName(_ equipment: Equipment) -> String {
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

struct EquipmentFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEquipment: Set<Equipment>
    let exerciseType: ExerciseType
    
    var availableEquipment: [Equipment] {
        switch exerciseType {
        case .strength:
            return [.barbell, .dumbbell, .cable, .machine, .bodyweight, .kettlebell, .resistanceBand, .ezBar, .trapBar, .smithMachine, .pullupBar, .dipBars, .bench, .inclineBench, .declineBench]
        case .cardio:
            return [.treadmill, .bike, .rowingMachine, .elliptical, .stairClimber, .jumpRope, .none]
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
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
            .navigationTitle("Filter by Equipment")
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
                    }
                    .disabled(selectedEquipment.isEmpty)
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
