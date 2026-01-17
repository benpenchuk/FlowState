//
//  NumberFormatter.swift
//  FlowState
//
//  Created by Ben Penchuk on 1/17/26.
//

import Foundation

extension Double {
    /// Formats a number with abbreviated notation (e.g., 24k, 2.1M, 1.5B)
    /// - Returns: A formatted string with abbreviated notation for large numbers
    func abbreviated() -> String {
        let absValue = abs(self)
        
        switch absValue {
        case 1_000_000_000...:
            // Billions
            let billions = self / 1_000_000_000
            let formatted = String(format: "%.1fB", billions)
            return formatted.replacingOccurrences(of: ".0B", with: "B")
        case 1_000_000...:
            // Millions
            let millions = self / 1_000_000
            let formatted = String(format: "%.1fM", millions)
            return formatted.replacingOccurrences(of: ".0M", with: "M")
        case 1_000...:
            // Thousands
            let thousands = self / 1_000
            let formatted = String(format: "%.1fk", thousands)
            return formatted.replacingOccurrences(of: ".0k", with: "k")
        default:
            // Less than 1000, format with comma separator
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            if let formatted = formatter.string(from: NSNumber(value: self)) {
                return formatted
            }
            return "\(Int(self))"
        }
    }
}

extension Int {
    /// Formats an integer with abbreviated notation (e.g., 24k, 2.1M, 1.5B)
    /// - Returns: A formatted string with abbreviated notation for large numbers
    func abbreviated() -> String {
        return Double(self).abbreviated()
    }
}
