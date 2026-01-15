//
//  PRNotificationView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI

struct PRNotificationView: View {
    let pr: PersonalRecord
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce, value: pr.id)
            
            Text("PERSONAL RECORD!")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let exerciseName = pr.exercise?.name {
                Text(exerciseName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                Text("\(String(format: "%.1f", pr.weight)) lbs")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("× \(pr.reps)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        PRNotificationView(
            pr: PersonalRecord(
                exercise: Exercise(name: "Bench Press", exerciseType: .strength, category: "Chest", equipment: [.barbell, .bench]),
                weight: 225,
                reps: 5
            )
        )
    }
}
