//
//  RestTimerView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI

struct RestTimerView: View {
    @ObservedObject var viewModel: RestTimerViewModel
    let onSkip: () -> Void
    
    @State private var scale: CGFloat = 1.0
    
    private var progress: Double {
        guard viewModel.totalSeconds > 0 else { return 0 }
        return Double(viewModel.remainingSeconds) / Double(viewModel.totalSeconds)
    }
    
    private var formattedTime: String {
        if viewModel.remainingSeconds >= 60 {
            let minutes = viewModel.remainingSeconds / 60
            let seconds = viewModel.remainingSeconds % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(viewModel.remainingSeconds)s"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Circular progress ring with time
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: viewModel.remainingSeconds)
                
                // Time text
                Text(formattedTime)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isComplete)
            .onChange(of: viewModel.isComplete) { oldValue, newValue in
                if newValue {
                    // Completion animation
                    withAnimation {
                        scale = 1.2
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            scale = 1.0
                        }
                    }
                }
            }
            
            // Controls
            HStack(spacing: 20) {
                Button {
                    viewModel.subtract30Seconds()
                } label: {
                    Label("-30s", systemImage: "minus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .disabled(!viewModel.isRunning || viewModel.remainingSeconds == 0)
                
                Button {
                    onSkip()
                } label: {
                    Label("Skip", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                }
                
                Button {
                    viewModel.add30Seconds()
                } label: {
                    Label("+30s", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .disabled(!viewModel.isRunning)
            }
            .padding(.horizontal)
            
            // Sound toggle button
            Button {
                viewModel.toggleSound()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.subheadline)
                    Text(viewModel.soundEnabled ? "Sound On" : "Sound Off")
                        .font(.caption)
                }
                .foregroundStyle(viewModel.soundEnabled ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .onAppear {
            // Update timer immediately when view appears (e.g., after app comes to foreground)
            if viewModel.isRunning {
                viewModel.refreshRemainingTime()
            }
        }
    }
}

#Preview {
    VStack {
        RestTimerView(
            viewModel: {
                let vm = RestTimerViewModel()
                vm.start(duration: 90)
                return vm
            }(),
            onSkip: {}
        )
    }
    .padding()
}
