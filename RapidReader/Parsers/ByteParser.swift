import Foundation

struct ByteParser {
    private static let hexChars = Array("0123456789ABCDEF")
    
    static func toHexString(_ data: Data) -> String {
        return data.map { byte in
            let unsigned = Int(byte) & 0xFF
            let highNibble = hexChars[(unsigned >> 4) & 0x0F]
            let lowNibble = hexChars[unsigned & 0x0F]
            return "\(highNibble)\(lowNibble)"
        }.joined(separator: " ")
    }
    
    static func extractInt16(_ data: Data, offset: Int = 0) -> Int? {
        guard data.count >= offset + 2 else { return nil }
        let low = Int(data[offset]) & 0xFF
        let high = Int(data[offset + 1]) & 0xFF
        return (high << 8) | low
    }
    
    static func extractInt24(_ data: Data, offset: Int = 0) -> Int? {
        guard data.count >= offset + 3 else { return nil }
        let b0 = Int(data[offset]) & 0xFF
        let b1 = Int(data[offset + 1]) & 0xFF
        let b2 = Int(data[offset + 2]) & 0xFF
        return (b2 << 16) | (b1 << 8) | b0
    }
    
    static func extractByte(_ data: Data, offset: Int) -> Int? {
        guard data.count > offset else { return nil }
        return Int(data[offset]) & 0xFF
    }
    
    static func extractInt24BigEndian(_ data: Data, offset: Int = 0) -> Int? {
        guard data.count >= offset + 3 else { return nil }
        let b0 = Int(data[offset]) & 0xFF
        let b1 = Int(data[offset + 1]) & 0xFF
        let b2 = Int(data[offset + 2]) & 0xFF
        return (b0 << 16) | (b1 << 8) | b2
    }
}
