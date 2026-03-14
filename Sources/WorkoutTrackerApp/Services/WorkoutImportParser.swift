import Foundation

struct ParsedImportLine {
    var name: String
    var sets: Int?
    var reps: Int?
    var seconds: Int?
    var weightKg: Double?
}

enum WorkoutImportParser {
    static func parse(raw: String) -> [ParsedImportLine] {
        raw
            .components(separatedBy: .newlines)
            .map { sanitize(line: $0) }
            .filter { !$0.isEmpty }
            .map(parseLine)
    }

    private static func sanitize(line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "- ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseLine(_ line: String) -> ParsedImportLine {
        var parsed = ParsedImportLine(name: line, sets: nil, reps: nil, seconds: nil, weightKg: nil)

        let normalized = line.lowercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")

        if let match = normalized.range(of: #"(\d{1,2})x(\d{1,3})"#, options: .regularExpression) {
            let pair = String(normalized[match]).split(separator: "x")
            if pair.count == 2 {
                parsed.sets = Int(pair[0])
                parsed.reps = Int(pair[1])
            }
        }

        if let secondsMatch = normalized.range(of: #"(\d{1,3})s"#, options: .regularExpression) {
            let value = String(normalized[secondsMatch]).replacingOccurrences(of: "s", with: "")
            parsed.seconds = Int(value)
            if parsed.reps == nil {
                parsed.reps = nil
            }
        }

        if let weightMatch = normalized.range(of: #"(\d+(?:\.\d+)?)kg"#, options: .regularExpression) {
            let rawWeight = String(normalized[weightMatch]).replacingOccurrences(of: "kg", with: "")
            parsed.weightKg = Double(rawWeight)
        }

        parsed.name = stripMetrics(from: line)
        return parsed
    }

    private static func stripMetrics(from line: String) -> String {
        let stripped = line
            .replacingOccurrences(of: #"\d+\s*x\s*\d+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\d+(?:[.,]\d+)?\s*kg(?:\s*x\s*\d+)?"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\d+\s*s"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return stripped.isEmpty ? line.trimmingCharacters(in: .whitespacesAndNewlines) : stripped
    }
}
