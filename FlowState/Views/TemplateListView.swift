//
//  TemplateListView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TemplateViewModel()
    @State private var showingCreateTemplate = false
    @State private var selectedTemplate: WorkoutTemplate? = nil
    @State private var templateToEdit: WorkoutTemplate? = nil
    @State private var templateToDelete: WorkoutTemplate? = nil
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Group {
            if viewModel.templates.isEmpty {
                emptyStateView
            } else {
                templateList
            }
        }
        .navigationTitle("Templates")
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                templateToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    viewModel.deleteTemplate(template)
                    templateToDelete = nil
                }
            }
        } message: {
            if let template = templateToDelete {
                Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedTemplate != nil },
            set: { if !$0 { selectedTemplate = nil } }
        )) {
            if let template = selectedTemplate {
                TemplateDetailView(template: template, viewModel: viewModel, isEditMode: false)
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { templateToEdit != nil },
            set: { if !$0 { templateToEdit = nil } }
        )) {
            if let template = templateToEdit {
                TemplateDetailView(template: template, viewModel: viewModel, isEditMode: true)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor.opacity(0.7))
            
            Text("No templates yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first workout routine!")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var templateList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.templates) { template in
                    TemplateListCardView(
                        template: template,
                        onTap: {
                            selectedTemplate = template
                        },
                        onEdit: {
                            templateToEdit = template
                        },
                        onDuplicate: {
                            viewModel.duplicateTemplate(template)
                        },
                        onDelete: {
                            templateToDelete = template
                            showingDeleteConfirmation = true
                        }
                    )
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            viewModel.duplicateTemplate(template)
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        .tint(Color.accentColor)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            templateToDelete = template
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
}

private func formatShortRelativeDate(_ date: Date) -> String {
    let diff = Int(Date().timeIntervalSince(date))
    if diff < 60 { return "now" }
    if diff < 3600 { return "\(diff / 60)m ago" }
    if diff < 86400 { return "\(diff / 3600)h ago" }
    if diff < 604800 { return "\(diff / 86400)d ago" }
    return date.formatted(.dateTime.month().day())
}

struct TemplateListCardView: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit Template", systemImage: "pencil")
                    }
                    
                    Button {
                        onDuplicate()
                    } label: {
                        Label("Duplicate Template", systemImage: "doc.on.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete Template", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 14) {
                let exerciseCount = template.exercises?.count ?? 0
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell")
                        .foregroundStyle(Color.accentColor)
                    Text("\(exerciseCount)")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                if let lastUsed = template.lastUsedAt {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(Color.accentColor.opacity(0.9))
                        Text(formatShortRelativeDate(lastUsed))
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(.tertiary)
                        Text("Never")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary.opacity(0.85))
                }
                
                Spacer(minLength: 0)
            }
            
            if let previewText = exercisePreviewText {
                Text(previewText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(12)
        .frame(minHeight: 90, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ActiveWorkoutLayout.exerciseCardCornerRadius, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var exercisePreviewText: String? {
        let exercises = template.exercises?.sorted(by: { $0.order < $1.order }) ?? []
        guard !exercises.isEmpty else { return nil }
        
        let names = exercises.prefix(3).map { $0.exercise?.name ?? "Unknown" }
        var preview = names.joined(separator: " • ")
        
        if exercises.count > 3 {
            preview += " • +\(exercises.count - 3) more"
        }
        
        return preview
    }
}

#Preview {
    NavigationStack {
        TemplateListView()
            .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, Exercise.self], inMemory: true)
    }
}
