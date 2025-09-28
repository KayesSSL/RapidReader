import Foundation

struct TimestampService {
    // MARK: - Locale helpers
    private static var isBengali: Bool {
        Locale.current.language.languageCode?.identifier == "bn"
    }
    
    private static let bengaliDigits = ["০","১","২","৩","৪","৫","৬","৭","৮","৯"]
    private static let englishDigits = ["0","1","2","3","4","5","6","7","8","9"]
    
    private static let bengaliMonths = ["জানুয়ারী","ফেব্রুয়ারী","মার্চ","এপ্রিল","মে","জুন","জুলাই","আগস্ট","সেপ্টেম্বর","অক্টোবর","নভেম্বর","ডিসেম্বর"]
    private static let englishMonths = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    
    private static let bengaliAM = "এএম"
    private static let bengaliPM = "পিএম"
    
    // MARK: - Helpers
    
    static func translateNumber(_ value: Int) -> String {
        let string = String(value)
        if isBengali {
            return string.compactMap { char in
                if let idx = englishDigits.firstIndex(of: String(char)) {
                    return bengaliDigits[idx]
                }
                return String(char)
            }.joined()
        } else {
            return string
        }
    }
    
    static func padStart(_ value: String, to length: Int, with pad: String) -> String {
        if value.count >= length { return value }
        return String(repeating: pad, count: length - value.count) + value
    }
    
    static func getMonth(_ month: Int) -> String {
        guard month >= 1 && month <= 12 else { return isBengali ? "অজানা" : "Unknown" }
        return isBengali ? bengaliMonths[month-1] : englishMonths[month-1]
    }
    
    static func getDefaultTimezone() -> TimeZone {
        TimeZone(identifier: "Asia/Dhaka") ?? .current
    }
    
    static func getAmPm(_ hour: Int) -> String {
        if isBengali {
            return hour < 12 ? bengaliAM : bengaliPM
        } else {
            return hour < 12 ? "AM" : "PM"
        }
    }
    
    static func getHour(_ hour: Int) -> String {
        let hour12: Int
        if hour == 0 {
            hour12 = 12
        } else if hour > 12 {
            hour12 = hour - 12
        } else {
            hour12 = hour
        }
        return padStart(translateNumber(hour12), to: 2, with: translateNumber(0))
    }
    
    // MARK: - Core Formatting
    
    /// Format a Date as "dd MMM yyyy, hh:mm AM/PM" with localized numbers and month name.
    static func formatDateTime(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents(in: getDefaultTimezone(), from: date)
        // Defensive: month and day default to 1 if nil
        let day = components.day ?? 1
        let month = components.month ?? 1
        let year = components.year ?? 2000
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        let zero = translateNumber(0)
        let dayStr = padStart(translateNumber(day), to: 2, with: zero)
        let monthStr = getMonth(month)
        let yearStr = translateNumber(year)
        
        let minutesStr: String
        if minute == 0 {
            minutesStr = ":\(zero)\(zero)"
        } else {
            minutesStr = ":\(padStart(translateNumber(minute), to: 2, with: zero))"
        }
        
        let hourStr = getHour(hour)
        let ampmStr = getAmPm(hour)
        
        return "\(dayStr) \(monthStr) \(yearStr), \(hourStr)\(minutesStr) \(ampmStr)"
    }
    
    // MARK: - Timestamp Decoding (as in the Kotlin code, but outputs Date)
    
    static func decodeTimestamp(_ value: Int) -> Date {
        let hour = (value >> 3) & 0x1F
        let day = (value >> 8) & 0x1F
        let month = (value >> 13) & 0x0F
        let year = (value >> 17) & 0x1F
        
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let baseYear = currentYear - (currentYear % 100)
        let fullYear = baseYear + year
        
        // Defensive: ensure month/day valid
        let validMonth = (1...12).contains(month) ? month : 1
        let validDay = (1...31).contains(day) ? day : 1
        
        var components = DateComponents()
        components.year = fullYear
        components.month = validMonth
        components.day = validDay
        components.hour = hour % 24
        components.minute = 0
        components.second = 0
        components.timeZone = getDefaultTimezone()
        
        return calendar.date(from: components) ?? now
    }
}
