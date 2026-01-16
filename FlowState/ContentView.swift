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
                
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            }
            .tint(.flowStateOrange)
            .preferredColorScheme(appearanceMode == .system ? nil : (appearanceMode == .dark ? .dark : .light))
            
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
            profileViewModel.setModelContext(modelContext)
            updateAppearanceMode()
        }
        .onChange(of: profileViewModel.profile?.appearanceMode) { oldValue, newValue in
            updateAppearanceMode()
        }
    }
    
    private func updateAppearanceMode() {
        if let profile = profileViewModel.profile {
            appearanceMode = profile.appearance
        }
    }
}




#Preview {
    ContentView()
}
