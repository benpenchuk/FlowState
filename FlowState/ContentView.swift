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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                
                NavigationStack {
                    HistoryView()
                }
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                
                NavigationStack {
                    ExerciseListView()
                }
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell")
                }
            }
            .preferredColorScheme(.dark)
            
            // Floating workout pill (shown when workout is active but minimized)
            if workoutState.activeWorkout != nil && !workoutState.isWorkoutFullScreen {
                FloatingWorkoutPill(workoutState: workoutState) {
                    workoutState.showWorkoutFullScreen()
                }
                .zIndex(1)
            }
        }
        .fullScreenCover(isPresented: $workoutState.isWorkoutFullScreen) {
            ActiveWorkoutFullScreenView()
                .environmentObject(workoutState)
        }
        .onAppear {
            workoutState.setModelContext(modelContext)
        }
    }
}




#Preview {
    ContentView()
}
