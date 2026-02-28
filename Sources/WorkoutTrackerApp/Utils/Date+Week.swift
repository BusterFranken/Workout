import Foundation

extension Calendar {
    static let workout: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()
}

extension Date {
    func startOfWorkoutWeek() -> Date {
        let calendar = Calendar.workout
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    func startOfDayDate() -> Date {
        Calendar.workout.startOfDay(for: self)
    }

    func isoShort() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
