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
}

#Preview {
    LabelPickerSheet(currentLabel: .warmup) { label in
        print("Selected: \(label)")
    }
}
