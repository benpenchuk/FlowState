//
//  ExerciseProgressChartView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/13/26.
//

import SwiftUI
import Charts

struct ExerciseProgressChartView: View {
    let progressionData: [(date: Date, weight: Double)]
    let prs: [PersonalRecord]
    
    var body: some View {
        if progressionData.isEmpty {
            emptyStateView
        } else {
            chartView
        }
    }
    
    private var chartView: some View {
        Chart {
            // Main progression line
            ForEach(Array(progressionData.enumerated()), id: \.offset) { index, dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Weight", dataPoint.weight)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                
                // Data points
                PointMark(
                    x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Weight", dataPoint.weight)
                )
                .foregroundStyle(.blue)
                .symbolSize(60)
            }
            
            // PR points highlighted
            ForEach(prs) { pr in
                PointMark(
                    x: .value("Date", pr.achievedAt, unit: .day),
                    y: .value("Weight", pr.weight)
                )
                .foregroundStyle(.yellow)
                .symbol {
                    Image(systemName: "star.fill")
                        .font(.caption)
                }
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, progressionData.count / 5))) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 200)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No data yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Complete workouts with this exercise to see your progress")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    let sampleData: [(date: Date, weight: Double)] = [
        (Calendar.current.date(byAdding: .day, value: -30, to: Date())!, 135),
        (Calendar.current.date(byAdding: .day, value: -20, to: Date())!, 140),
        (Calendar.current.date(byAdding: .day, value: -10, to: Date())!, 145),
        (Date(), 150)
    ]
    
    let samplePRs: [PersonalRecord] = [
        PersonalRecord(
            exercise: Exercise(name: "Bench Press", exerciseType: .strength, category: "Chest", equipment: [.barbell, .bench]),
            weight: 150,
            reps: 5,
            achievedAt: Date()
        )
    ]
    
    return ExerciseProgressChartView(
        progressionData: sampleData,
        prs: samplePRs
    )
    .padding()
}
