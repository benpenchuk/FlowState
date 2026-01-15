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
            PersonalRecord.self,
        ])
        
        // For development: Use a specific URL to allow easy database reset
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = appSupportURL.appendingPathComponent("FlowState.sqlite")
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try to delete and recreate (development only)
            print("⚠️ ModelContainer creation failed: \(error)")
            print("⚠️ This is likely due to schema changes. Attempting to delete old database and recreate...")
            
            // Delete the old database files
            let dbURL = url
            let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
            
            try? fileManager.removeItem(at: dbURL)
            try? fileManager.removeItem(at: shmURL)
            try? fileManager.removeItem(at: walURL)
            
            print("⚠️ Old database files deleted. Creating fresh database...")
            
            // Try again with fresh database
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ Successfully created new ModelContainer")
                return container
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
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
