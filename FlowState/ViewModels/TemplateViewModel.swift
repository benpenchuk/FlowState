//
//  TemplateViewModel.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import Foundation
import SwiftData
import SwiftUI
import Combine

final class TemplateViewModel: ObservableObject {
    @Published var templates: [WorkoutTemplate] = []
    @Published var isLoading = false
    
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchAllTemplates()
    }
    
    func fetchAllTemplates() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let fetched = try modelContext.fetch(descriptor)
            templates = fetched.sorted { template1, template2 in
                // Sort by lastUsedAt first (most recent first), then by createdAt
                if let lastUsed1 = template1.lastUsedAt, let lastUsed2 = template2.lastUsedAt {
                    return lastUsed1 > lastUsed2
                } else if template1.lastUsedAt != nil {
                    return true
                } else if template2.lastUsedAt != nil {
                    return false
                } else {
                    return template1.createdAt > template2.createdAt
                }
            }
        } catch {
            print("Error fetching templates: \(error)")
            templates = []
        }
        
        isLoading = false
    }
    
    func createTemplate(name: String, exercises: [(Exercise, defaultSets: Int, defaultReps: Int, defaultWeight: Double?)]) {
        guard let modelContext = modelContext else { return }
        
        let template = WorkoutTemplate(name: name, createdAt: Date())
        modelContext.insert(template)
        
        var templateExercises: [TemplateExercise] = []
        for (index, exerciseData) in exercises.enumerated() {
            let templateExercise = TemplateExercise(
                exercise: exerciseData.0,
                order: index,
                defaultSets: exerciseData.defaultSets,
                defaultReps: exerciseData.defaultReps,
                defaultWeight: exerciseData.defaultWeight
            )
            templateExercise.template = template
            templateExercises.append(templateExercise)
            modelContext.insert(templateExercise)
        }
        
        template.exercises = templateExercises
        
        do {
            try modelContext.save()
            fetchAllTemplates()
        } catch {
            print("Error creating template: \(error)")
        }
    }
    
    func updateTemplate(_ template: WorkoutTemplate) {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            fetchAllTemplates()
        } catch {
            print("Error updating template: \(error)")
        }
    }
    
    func updateTemplateExercises(_ template: WorkoutTemplate, exercises: [TemplateExercise]) {
        print("🟡 TemplateViewModel.updateTemplateExercises() called")
        print("🟡 Template: \(template.name)")
        print("🟡 Number of exercises passed: \(exercises.count)")
        print("🟡 Current template.exercises count: \(template.exercises?.count ?? 0)")
        
        guard let modelContext = modelContext else {
            print("🔴 No modelContext available")
            return
        }
        
        // Find exercises to delete (ones that are in template.exercises but not in the new exercises array)
        if let oldExercises = template.exercises {
            let newExerciseIds = Set(exercises.map { $0.id })
            let exercisesToDelete = oldExercises.filter { !newExerciseIds.contains($0.id) }
            
            print("🟡 Exercises to delete: \(exercisesToDelete.count)")
            for oldExercise in exercisesToDelete {
                print("🟡 Deleting: \(oldExercise.exercise?.name ?? "unknown")")
                modelContext.delete(oldExercise)
            }
        }
        
        // Update order and ensure all exercises are linked and inserted
        for (index, exercise) in exercises.enumerated() {
            exercise.order = index
            exercise.template = template
            
            // Insert if not already in context
            if exercise.modelContext == nil {
                print("🟡 Inserting new exercise: \(exercise.exercise?.name ?? "unknown")")
                modelContext.insert(exercise)
            }
        }
        
        template.exercises = exercises
        
        print("🟡 Template exercises count after update: \(template.exercises?.count ?? 0)")
        
        do {
            try modelContext.save()
            print("🟡 modelContext.save() successful in updateTemplateExercises")
            fetchAllTemplates()
        } catch {
            print("🔴 Error updating template exercises: \(error)")
        }
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        guard let modelContext = modelContext else { return }
        
        modelContext.delete(template)
        
        do {
            try modelContext.save()
            fetchAllTemplates()
        } catch {
            print("Error deleting template: \(error)")
        }
    }
    
    func markTemplateUsed(_ template: WorkoutTemplate) {
        template.lastUsedAt = Date()
        updateTemplate(template)
    }
    
    func duplicateTemplate(_ template: WorkoutTemplate) {
        guard let modelContext = modelContext else { return }
        
        // Create new template with " (Copy)" suffix
        let newTemplate = WorkoutTemplate(name: "\(template.name) (Copy)", createdAt: Date())
        modelContext.insert(newTemplate)
        
        // Duplicate all exercises
        if let exercises = template.exercises?.sorted(by: { $0.order < $1.order }) {
            var newExercises: [TemplateExercise] = []
            for exercise in exercises {
                let newTemplateExercise = TemplateExercise(
                    exercise: exercise.exercise!,
                    order: exercise.order,
                    defaultSets: exercise.defaultSets,
                    defaultReps: exercise.defaultReps,
                    defaultWeight: exercise.defaultWeight
                )
                newTemplateExercise.template = newTemplate
                newExercises.append(newTemplateExercise)
                modelContext.insert(newTemplateExercise)
            }
            newTemplate.exercises = newExercises
        }
        
        do {
            try modelContext.save()
            fetchAllTemplates()
        } catch {
            print("Error duplicating template: \(error)")
        }
    }
}
