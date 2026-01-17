//
//  LabelPickerSheet.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/16/26.
//

import SwiftUI

struct LabelPickerSheet: View {
    let currentLabel: SetLabel
    let onSelect: (SetLabel) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Set Label")
                    .font(.headline)
                    .padding(.top, 8)
                
                List {
                    ForEach(SetLabel.allCases, id: \.self) { label in
                        Button {
                            onSelect(label)
                        } label: {
                            HStack {
                                // Label indicator
                                Circle()
                                    .fill(labelColor(for: label))
                                    .frame(width: 12, height: 12)
                                
                                Text(label.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if label == currentLabel {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func labelColor(for label: SetLabel) -> Color {
        switch label {
        case .none:
            return .gray.opacity(0.5)
        case .warmup:
            return .cyan
        case .failure:
            return .red
        case .dropSet:
            return .purple
        case .prAttempt:
            return .yellow
        }
    }
}

#Preview {
    LabelPickerSheet(currentLabel: .warmup) { label in
        print("Selected: \(label)")
    }
}
