//
//  SkeletonWorkoutHistoryCard.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/17/26.
//

import SwiftUI

struct SkeletonWorkoutHistoryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 18)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 12)
            }
            
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 12)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 12)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 12)
            }
        }
        .padding(.vertical, 4)
        .redacted(reason: .placeholder)
    }
}

#Preview {
    List {
        SkeletonWorkoutHistoryCard()
        SkeletonWorkoutHistoryCard()
        SkeletonWorkoutHistoryCard()
    }
}
