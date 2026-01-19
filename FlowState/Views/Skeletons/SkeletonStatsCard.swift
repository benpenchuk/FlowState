//
//  SkeletonStatsCard.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/19/26.
//

import SwiftUI

struct SkeletonStatsCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                // Workouts Count Skeleton
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(width: 50, height: 32)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 12)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                // Total Time Skeleton
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 32)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 12)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 50)
                
                // Current Streak Skeleton
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(width: 40, height: 32)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .redacted(reason: .placeholder)
    }
}

#Preview {
    SkeletonStatsCard()
        .padding()
}
