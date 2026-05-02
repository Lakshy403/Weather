import Foundation
import Combine
import SwiftUI

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var weather: WeatherResponse?
    @Published var forecast: [ForecastItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let locationManager = LocationManager()
    private let weatherService = WeatherService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupLocationObserver()
        loadFromCache()
    }
    
    // MARK: - CoreLogic
    
    private func setupLocationObserver() {
        locationManager.$location
            .compactMap { $0 }
            .sink { [weak self] location in
                Task {
                    await self?.fetchWeatherForLocation(lat: location.latitude, lon: location.longitude)
                }
            }
            .store(in: &cancellables)
            
        locationManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                let errMessage = error.localizedDescription
                self?.errorMessage = "Location Error: \(errMessage). Showing offline data if available."
            }
            .store(in: &cancellables)
    }
    
    func fetchMetrics() {
        // If we don't have weather loaded, request location to auto-fetch
        if weather == nil {
            locationManager.requestLocation()
        }
    }
    
    func fetchWeatherForLocation(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedWeather = try await weatherService.fetchWeather(lat: lat, lon: lon)
            let fetchedForecast = try await weatherService.fetchForecast(lat: lat, lon: lon)
            
            self.weather = fetchedWeather
            self.forecast = filterDailyForecast(fetchedForecast.list)
            saveToCache()
            
        } catch {
            self.errorMessage = "Could not fetch data. Displaying cached data."
            loadFromCache()
        }
        isLoading = false
    }
    
    func fetchWeatherForCity(city: String) async {
        let cleanCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCity.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        do {
            let fetchedWeather = try await weatherService.fetchWeather(city: cleanCity)
            let fetchedForecast = try await weatherService.fetchForecast(city: cleanCity)
            
            self.weather = fetchedWeather
            self.forecast = filterDailyForecast(fetchedForecast.list)
            saveToCache()
            
        } catch {
            self.errorMessage = "Could not find weather for \(cleanCity). Try again."
        }
        isLoading = false
    }
    
    // Evaluates OpenWeatherMap's 3-hour chunks and pulls out exactly 1 unique day per element
    private func filterDailyForecast(_ list: [ForecastItem]) -> [ForecastItem] {
        var uniqueDays = Set<Int>()
        var filteredList = [ForecastItem]()
        
        let calendar = Calendar.current
        for item in list {
            let day = calendar.component(.day, from: item.date)
            // Save around Noon timeframe if desired, simplifying heavily to just first time of day
            if !uniqueDays.contains(day) {
                uniqueDays.insert(day)
                filteredList.append(item)
            }
        }
        
        // We only want 5 days total, Drop "Today" if needed, just showing prefix 5 here
        return Array(filteredList.prefix(5))
    }
    
    // MARK: - Presentation Formatters
    
    func weatherIcon(for condition: String) -> String {
        let conditionCode = condition.lowercased()
        switch conditionCode {
        case "clear": return "sun.max.fill"
        case "clouds": return "cloud.fill"
        case "rain": return "cloud.rain.fill"
        case "drizzle": return "cloud.drizzle.fill"
        case "thunderstorm": return "cloud.bolt.rain.fill"
        case "snow": return "cloud.snow.fill"
        case "mist", "smoke", "haze", "dust", "fog", "sand", "ash", "squall", "tornado": return "cloud.fog.fill"
        default: return "cloud.fill" // generic fallback
        }
    }
    
    var backgroundColors: [Color] {
        guard let weather = weather else {
            return [.blue, .cyan]
        }
        
        // Use basic colors from SwiftUI that scale for Dark/Light automatically 
        let condition = weather.weather.first?.main.lowercased() ?? ""
        switch condition {
        case "clear":
            return [.blue, .cyan]
        case "clouds":
            return [.gray, .cyan.opacity(0.8)]
        case "rain", "drizzle", "thunderstorm":
            return [.indigo, .gray]
        case "snow":
            return [.cyan.opacity(0.3), .white.opacity(0.8)]
        default:
            return [.blue, .cyan]
        }
    }
    
    // MARK: - Offline Caching
    
    private func saveToCache() {
        if let weather = weather, let encoded = try? JSONEncoder().encode(weather) {
            UserDefaults.standard.set(encoded, forKey: "cachedWeather")
        }
        if let encoded = try? JSONEncoder().encode(forecast) {
            UserDefaults.standard.set(encoded, forKey: "cachedForecast")
        }
    }
    
    private func loadFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedWeather"),
           let cached = try? JSONDecoder().decode(WeatherResponse.self, from: data) {
            self.weather = cached
        }
        if let data = UserDefaults.standard.data(forKey: "cachedForecast"),
           let cached = try? JSONDecoder().decode([ForecastItem].self, from: data) {
            self.forecast = cached
        }
    }
}
