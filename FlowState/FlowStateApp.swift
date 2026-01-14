//
//  FlowStateApp.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

@main
struct FlowStateApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            Workout.self,
            WorkoutEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var workoutStateManager = WorkoutStateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(workoutStateManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
