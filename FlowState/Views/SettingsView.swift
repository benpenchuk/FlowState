//
//  SettingsView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData
import MessageUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingExportAlert = false
    @State private var showingClearDataAlert = false
    @State private var showingAboutAlert = false
    @State private var showingMailComposer = false
    @State private var canSendMail = false
    
    var body: some View {
        NavigationStack {
            Form {
                preferencesSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                canSendMail = MFMailComposeViewController.canSendMail()
            }
            .alert("Export Data", isPresented: $showingExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Export functionality coming soon!")
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all workouts, exercises, templates, and personal records. This action cannot be undone.")
            }
            .alert("About FlowState", isPresented: $showingAboutAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("FlowState is a workout tracking app designed to help you stay consistent and track your progress. Built with SwiftUI and SwiftData.")
            }
            .sheet(isPresented: $showingMailComposer) {
                if canSendMail {
                    MailComposeView()
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        Section("Preferences") {
            // Units Picker
            if let profile = viewModel.profile {
                Picker("Units", selection: Binding(
                    get: { profile.units },
                    set: { viewModel.updatePreferredUnits($0) }
                )) {
                    ForEach(Units.allCases, id: \.self) { unit in
                        Text(unit.rawValue.uppercased()).tag(unit)
                    }
                }
                
                // Default Rest Time
                Picker("Default Rest Time", selection: Binding(
                    get: { profile.defaultRestTime },
                    set: { viewModel.updateDefaultRestTime($0) }
                )) {
                    Text("30s").tag(30)
                    Text("60s").tag(60)
                    Text("90s").tag(90)
                    Text("120s").tag(120)
                    Text("180s").tag(180)
                }
                
                // Appearance Mode
                Picker("Appearance", selection: Binding(
                    get: { profile.appearance },
                    set: { viewModel.updateAppearanceMode($0) }
                )) {
                    Text("Dark").tag(AppearanceMode.dark)
                    Text("Light").tag(AppearanceMode.light)
                    Text("System").tag(AppearanceMode.system)
                }
            }
        }
    }
    
    private var dataSection: some View {
        Section("Data") {
            Button {
                showingExportAlert = true
            } label: {
                HStack {
                    Text("Export Workout Data")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button(role: .destructive) {
                showingClearDataAlert = true
            } label: {
                HStack {
                    Text("Clear All Data")
                    Spacer()
                }
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                if canSendMail {
                    showingMailComposer = true
                } else {
                    // Fallback: copy email to clipboard or show alert
                    showingExportAlert = true
                }
            } label: {
                HStack {
                    Text("Send Feedback")
                    Spacer()
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                showingAboutAlert = true
            } label: {
                HStack {
                    Text("About FlowState")
                    Spacer()
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private func clearAllData() {
        // Delete all workouts
        let workoutDescriptor = FetchDescriptor<Workout>()
        if let workouts = try? modelContext.fetch(workoutDescriptor) {
            for workout in workouts {
                modelContext.delete(workout)
            }
        }
        
        // Delete all exercises (only custom ones, but we'll delete all for clear data)
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        if let exercises = try? modelContext.fetch(exerciseDescriptor) {
            for exercise in exercises {
                modelContext.delete(exercise)
            }
        }
        
        // Delete all templates
        let templateDescriptor = FetchDescriptor<WorkoutTemplate>()
        if let templates = try? modelContext.fetch(templateDescriptor) {
            for template in templates {
                modelContext.delete(template)
            }
        }
        
        // Delete all PRs
        let prDescriptor = FetchDescriptor<PersonalRecord>()
        if let prs = try? modelContext.fetch(prDescriptor) {
            for pr in prs {
                modelContext.delete(pr)
            }
        }
        
        // Save changes
        try? modelContext.save()
        
        // Refresh stats
        viewModel.refreshStats()
        
        dismiss()
    }
}

// Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(["feedback@flowstate.app"]) // Placeholder email
        composer.setSubject("FlowState Feedback")
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        
        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
