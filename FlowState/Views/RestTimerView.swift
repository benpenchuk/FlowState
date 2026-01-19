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
        HStack(spacing: 16) {
            // Circular progress ring with time
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: viewModel.remainingSeconds)
                
                // Time text
                Text(formattedTime)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
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
            
            // Controls - inline horizontal
            HStack(spacing: 16) {
                Button {
                    viewModel.subtract30Seconds()
                } label: {
                    Label("-30s", systemImage: "minus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .labelStyle(.titleAndIcon)
                }
                .disabled(!viewModel.isRunning || viewModel.remainingSeconds == 0)
                
                Button {
                    onSkip()
                } label: {
                    Label("Skip", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                        .labelStyle(.titleAndIcon)
                }
                
                Button {
                    viewModel.add30Seconds()
                } label: {
                    Label("+30s", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .labelStyle(.titleAndIcon)
                }
                .disabled(!viewModel.isRunning)
            }
            
            Spacer()
            
            // Sound toggle button (icon only)
            Button {
                viewModel.toggleSound()
            } label: {
                Image(systemName: viewModel.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(viewModel.soundEnabled ? .orange : .secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
