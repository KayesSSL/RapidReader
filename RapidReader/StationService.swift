struct StationService {
    static let stationMap: [Int: String] = [
        10: "Motijheel",
        20: "Bangladesh Secretariat",
        25: "Dhaka University",
        30: "Shahbagh",
        35: "Karwan Bazar",
        40: "Farmgate",
        45: "Bijoy Sarani",
        50: "Agargaon",
        55: "Shewrapara",
        60: "Kazipara",
        65: "Mirpur 10",
        70: "Mirpur 11",
        75: "Pallabi",
        80: "Uttara South",
        85: "Uttara Center",
        90: "Uttara North"
    ]
    static func getStationName(_ code: Int) -> String {
        return stationMap[code] ?? "Unknown Station (\(code))"
    }
}
