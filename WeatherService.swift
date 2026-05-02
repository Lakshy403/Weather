import Foundation

class WeatherService {
    // ⚠️ Replace this with your actual OpenWeatherMap API Key
    private let apiKey = "YOUR_API_KEY_HERE"
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    // Fetch Weather by Coordinates
    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherResponse {
        let urlString = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        return try await performRequest(urlString: urlString, type: WeatherResponse.self)
    }
    
    // Fetch Forecast by Coordinates
    func fetchForecast(lat: Double, lon: Double) async throws -> ForecastResponse {
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        return try await performRequest(urlString: urlString, type: ForecastResponse.self)
    }
    
    // Fetch Weather by City
    func fetchWeather(city: String) async throws -> WeatherResponse {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/weather?q=\(encodedCity)&appid=\(apiKey)&units=metric"
        return try await performRequest(urlString: urlString, type: WeatherResponse.self)
    }
    
    // Fetch Forecast by City
    func fetchForecast(city: String) async throws -> ForecastResponse {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/forecast?q=\(encodedCity)&appid=\(apiKey)&units=metric"
        return try await performRequest(urlString: urlString, type: ForecastResponse.self)
    }
    
    private func performRequest<T: Codable>(urlString: String, type: T.Type) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            // Detailed error handling could go here based on OWMA's response
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
