import Foundation

enum Formatting {
    static func compactKg(_ value: Double?) -> String {
        guard let value else { return "BW" }
        if value.rounded() == value {
            return "\(Int(value))kg"
        }
        return "\(String(format: "%.1f", value))kg"
    }

    static func kgWithCount(_ kg: Double?, count: Int?) -> String {
        guard let kg else { return "BW" }
        let base = compactKg(kg)
        guard let count, count > 1 else { return base }
        return "\(base)x\(count)"
    }

    static func numericOrEmpty(_ value: Int?) -> String {
        guard let value else { return "" }
        return String(value)
    }

    static func parseWeightEntry(_ raw: String) -> (weightKg: Double?, count: Int?) {
        let trimmed = raw.lowercased().replacingOccurrences(of: " ", with: "")
        if trimmed.isEmpty || trimmed == "bw" {
            return (nil, nil)
        }

        let parts = trimmed.split(separator: "x")
        if parts.count == 2 {
            let weight = Double(parts[0].replacingOccurrences(of: "kg", with: ""))
            let count = Int(parts[1])
            return (weight, count)
        }

        return (Double(trimmed.replacingOccurrences(of: "kg", with: "")), nil)
    }
}
