import Foundation

// MARK: - Current Weather Response
struct WeatherResponse: Codable {
    let name: String
    let main: MainWeather
    let weather: [Weather]
    let wind: Wind
}

struct MainWeather: Codable {
    let temp: Double
    let feelsLike: Double
    let humidity: Double
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
    }
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct Wind: Codable {
    let speed: Double
}

// MARK: - Forecast Response
struct ForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable, Identifiable {
    let dt: TimeInterval
    let main: MainWeather
    let weather: [Weather]
    
    var id: TimeInterval { dt }
    var date: Date { Date(timeIntervalSince1970: dt) }
}
