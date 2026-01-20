//
//  ContentView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var workoutState: WorkoutStateManager
    @Environment(\.modelContext) private var modelContext
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var appearanceMode: AppearanceMode = .system
    @State private var showingResumeWorkoutAlert = false
    @State private var incompleteWorkout: Workout? = nil
    
    var body: some View {
        TabView {
            tabRoot {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            tabRoot {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock")
            }
            
            tabRoot {
                ExerciseListView()
            }
            .tabItem {
                Label("Exercises", systemImage: "dumbbell")
            }
            
            tabRoot {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
        }
        .fullScreenCover(isPresented: $workoutState.isWorkoutFullScreen) {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ActiveWorkoutFullScreenView()
                    .environmentObject(workoutState)
            }
        }
        .tint(.flowStateOrange)
        .preferredColorScheme(appearanceMode == .system ? nil : (appearanceMode == .dark ? .dark : .light))
        .onAppear {
            profileViewModel.setModelContext(modelContext)
            updateAppearanceMode()
            // Check for incomplete workout BEFORE setting model context
            // This allows us to show the alert before auto-loading
            checkForIncompleteWorkout()
            // Only set model context if no incomplete workout was found
            // Otherwise, it will be set when user chooses to resume or discard
            if incompleteWorkout == nil {
                workoutState.setModelContext(modelContext)
            }
        }
        .alert("Resume Workout?", isPresented: $showingResumeWorkoutAlert) {
            Button("Discard", role: .destructive) {
                discardIncompleteWorkout()
            }
            Button("Resume") {
                resumeIncompleteWorkout()
            }
        } message: {
            if let workout = incompleteWorkout {
                let workoutName = workout.name ?? "Unnamed Workout"
                let startedAt = workout.startedAt
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return Text("You have an incomplete workout: \"\(workoutName)\" started on \(formatter.string(from: startedAt)). Would you like to resume it or discard it?")
            } else {
                return Text("You have an incomplete workout. Would you like to resume it or discard it?")
            }
        }
        .onChange(of: profileViewModel.profile?.appearanceMode) { oldValue, newValue in
            updateAppearanceMode()
        }
    }

    private var shouldShowWorkoutPill: Bool {
        workoutState.activeWorkout != nil &&
            !workoutState.isWorkoutFullScreen
    }
    
    @ViewBuilder
    private func tabRoot<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
        }
        .safeAreaInset(edge: .bottom) {
            if shouldShowWorkoutPill {
                FloatingWorkoutPill(workoutState: workoutState) {
                    workoutState.showWorkoutFullScreen()
                }
            }
        }
    }
    
    private func updateAppearanceMode() {
        if let profile = profileViewModel.profile {
            appearanceMode = profile.appearance
        }
    }
    
    private func checkForIncompleteWorkout() {
        // Check for incomplete workout before WorkoutStateManager auto-loads it
        let descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { workout in
                workout.completedAt == nil
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        
        do {
            let workouts = try modelContext.fetch(descriptor)
            if let workout = workouts.first {
                incompleteWorkout = workout
                showingResumeWorkoutAlert = true
            }
        } catch {
            print("Error checking for incomplete workout: \(error)")
        }
    }
    
    private func resumeIncompleteWorkout() {
        if let workout = incompleteWorkout {
            // Ensure model context is set before resuming
            workoutState.setModelContext(modelContext)
            workoutState.setActiveWorkout(workout)
            workoutState.showWorkoutFullScreen()
            incompleteWorkout = nil
        }
    }
    
    private func discardIncompleteWorkout() {
        if let workout = incompleteWorkout {
            modelContext.delete(workout)
            do {
                try modelContext.save()
            } catch {
                print("Error discarding incomplete workout: \(error)")
            }
            incompleteWorkout = nil
            // Now set model context (no workout to load)
            workoutState.setModelContext(modelContext)
        }
    }
}




#Preview {
    ContentView()
}
