//
//  CustomNumPadView.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/16/26.
//

import SwiftUI

struct CustomNumPadView: View {
    @Binding var value: String
    let showDecimal: Bool
    let fieldLabel: String
    let preferredUnits: Units?
    let onDone: () -> Void
    
    // Maximum weight limits
    private let maxWeightLbs: Double = 2000.0
    private let maxWeightKg: Double = 1000.0
    
    private var maxWeight: Double {
        preferredUnits == .kg ? maxWeightKg : maxWeightLbs
    }
    
    private var isValueValid: Bool {
        guard !value.isEmpty, let doubleValue = Double(value) else {
            return true
        }
        // Only check max weight for weight fields
        if showDecimal, let preferredUnits = preferredUnits {
            let max = preferredUnits == .kg ? maxWeightKg : maxWeightLbs
            return doubleValue <= max
        }
        return true
    }
    
    var body: some View {
        GeometryReader { geometry in
        VStack(spacing: 0) {
            // Live display box at top
            VStack(spacing: 8) {
                Text(fieldLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.top, 4)
                Text(value.isEmpty ? "0" : value)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(isValueValid ? Color.primary : Color.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(width: geometry.size.width, alignment: .center)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color(.separator)),
                alignment: .bottom
            )
            
            // Number pad grid
            VStack(spacing: 12) {
                // Row 1: 1, 2, 3
                HStack(spacing: 12) {
                    numPadButton("1")
                    numPadButton("2")
                    numPadButton("3")
                }
                
                // Row 2: 4, 5, 6
                HStack(spacing: 12) {
                    numPadButton("4")
                    numPadButton("5")
                    numPadButton("6")
                }
                
                // Row 3: 7, 8, 9
                HStack(spacing: 12) {
                    numPadButton("7")
                    numPadButton("8")
                    numPadButton("9")
                }
                
                // Row 4: Decimal (conditional), 0, Backspace
                HStack(spacing: 12) {
                    if showDecimal {
                        numPadButton(".")
                    } else {
                        Spacer()
                            .frame(width: 100)
                    }
                    numPadButton("0")
                    backspaceButton
                }
            }
            .frame(width: geometry.size.width)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(Color(.systemGray6))
            
            // Done button
            Button {
                onDone()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: geometry.size.width)
                    .frame(height: 50)
                    .background(Color.orange)
            }
        }
        .frame(width: geometry.size.width)
        .background(Color(.systemGray6))
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func numPadButton(_ digit: String) -> some View {
        Button {
            handleDigitInput(digit)
        } label: {
            Text(digit)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 100, height: 50)
                .background(Color(.systemBackground))
                .cornerRadius(8)
        }
    }
    
    private func handleDigitInput(_ digit: String) {
        // Prevent multiple decimal points
        if digit == "." {
            if value.contains(".") {
                return // Already has decimal point
            }
            // Can't start with decimal point
            if value.isEmpty {
                value = "0."
                return
            }
            value += digit
            return
        }
        
        // Check decimal place restriction (only one digit after decimal)
        if value.contains(".") {
            let parts = value.split(separator: ".")
            if parts.count == 2 && parts[1].count >= 1 {
                // Already has one decimal place, don't allow more
                return
            }
        }
        
        // Check max weight limit (only for weight fields)
        if showDecimal, let preferredUnits = preferredUnits {
            let testValue = value + digit
            if let doubleValue = Double(testValue) {
                let max = preferredUnits == .kg ? maxWeightKg : maxWeightLbs
                if doubleValue > max {
                    // Exceeds max weight, don't allow
                    return
                }
            }
        }
        
        value += digit
    }
    
    private var backspaceButton: some View {
        Button {
            if !value.isEmpty {
                value.removeLast()
            }
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 100, height: 50)
                .background(Color(.systemBackground))
                .cornerRadius(8)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        CustomNumPadView(
            value: .constant("135.5"),
            showDecimal: true,
            fieldLabel: "Weight",
            preferredUnits: .lbs
        ) {
            // onDone closure
        }
    }
    .background(Color(.systemBackground))
}
