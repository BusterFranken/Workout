import Foundation

enum Formatting {
    static func compactWeight(_ kgValue: Double?, unit: UnitSystem) -> String {
        guard let kgValue else { return "BW" }

        let displayValue: Double
        let suffix: String

        switch unit {
        case .kg:
            displayValue = kgValue
            suffix = "kg"
        case .lb:
            displayValue = kgValue * 2.2046226218
            suffix = "lb"
        }

        if displayValue.rounded() == displayValue {
            return "\(Int(displayValue))\(suffix)"
        }

        return "\(String(format: "%.1f", displayValue))\(suffix)"
    }

    static func numericOrEmpty(_ value: Int?) -> String {
        guard let value else { return "" }
        return String(value)
    }

    static func parseWeightEntry(_ raw: String, unit: UnitSystem) -> Double? {
        let trimmed = raw.lowercased().replacingOccurrences(of: " ", with: "")

        if trimmed.isEmpty || trimmed == "bw" {
            return nil
        }

        var value = trimmed
            .replacingOccurrences(of: "kg", with: "")
            .replacingOccurrences(of: "lb", with: "")

        if let xIndex = value.firstIndex(of: "x") {
            value = String(value[..<xIndex])
        }

        guard let parsed = Double(value) else {
            return nil
        }

        switch unit {
        case .kg:
            return parsed
        case .lb:
            return parsed / 2.2046226218
        }
    }

    static func weightPlaceholder(for unit: UnitSystem) -> String {
        switch unit {
        case .kg:
            return "kg"
        case .lb:
            return "lb"
        }
    }
}
