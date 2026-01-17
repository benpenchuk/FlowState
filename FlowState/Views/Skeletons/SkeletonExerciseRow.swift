//
//  SkeletonExerciseRow.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/17/26.
//

import SwiftUI

struct SkeletonExerciseRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Star icon placeholder
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 150, height: 16)
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 12)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 12)
                }
            }
            
            Spacer()
        }
        .redacted(reason: .placeholder)
    }
}

#Preview {
    List {
        SkeletonExerciseRow()
        SkeletonExerciseRow()
        SkeletonExerciseRow()
    }
}
