//
//  SkeletonTemplateCard.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/17/26.
//

import SwiftUI

struct SkeletonTemplateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title and play icon placeholder
            HStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 18)
                
                Spacer()
                
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 18, height: 18)
            }
            .padding(.bottom, 10)
            
            // Exercise list placeholders
            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<3) { _ in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 4, height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 12)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(width: 30, height: 10)
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // Bottom info placeholder (Last used and Count)
            HStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 10)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(width: 30, height: 10)
            }
        }
        .padding(14)
        .frame(width: 220, height: 150, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .redacted(reason: .placeholder)
    }
}

#Preview {
    SkeletonTemplateCard()
}
