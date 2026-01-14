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
    
    var body: some View {
        Group {
            if viewModel.templates.isEmpty {
                emptyStateView
            } else {
                templateList
            }
        }
        .navigationTitle("Templates")
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
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No templates yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first workout routine!")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var templateList: some View {
        List {
            ForEach(viewModel.templates) { template in
                NavigationLink {
                    TemplateDetailView(template: template, viewModel: viewModel)
                } label: {
                    TemplateRowView(template: template)
                }
            }
            .onDelete { indexSet in
                deleteTemplates(at: indexSet)
            }
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = viewModel.templates[index]
            viewModel.deleteTemplate(template)
        }
    }
}

struct TemplateRowView: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.name)
                .font(.headline)
            
            HStack(spacing: 16) {
                Label("\(template.exercises?.count ?? 0) exercises", systemImage: "dumbbell")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let lastUsed = template.lastUsedAt {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(lastUsed, format: .dateTime.month().day().year())
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TemplateListView()
            .modelContainer(for: [WorkoutTemplate.self, TemplateExercise.self, Exercise.self], inMemory: true)
    }
}
