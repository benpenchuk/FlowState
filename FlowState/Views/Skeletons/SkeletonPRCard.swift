//
//  SkeletonPRCard.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/17/26.
//

import SwiftUI

struct SkeletonPRCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 18)
                
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 14)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(width: 30, height: 14)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 12)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 40, height: 10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .redacted(reason: .placeholder)
    }
}

#Preview {
    VStack {
        SkeletonPRCard()
        SkeletonPRCard()
    }
    .padding()
}
