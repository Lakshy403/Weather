import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @State private var searchQuery = ""
    
    var body: some View {
        ZStack {
            // MARK: - Dynamic Background
            LinearGradient(colors: viewModel.backgroundColors,
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: viewModel.backgroundColors)
            
            VStack {
                // MARK: - Search Header
                searchHeader
                
                // MARK: - Main Content
                if viewModel.isLoading && viewModel.weather == nil {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let weather = viewModel.weather {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // User Alerts / Errors
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(10)
                            }
                            
                            // Hero View
                            heroSection(weather: weather)
                            
                            // Real Time Metrics Grid
                            metricsGrid(weather: weather)
                            
                            // 5-Day Forecast
                            if !viewModel.forecast.isEmpty {
                                forecastSection
                            }
                        }
                        .padding(.top, 20)
                    }
                    .refreshable {
                        if !searchQuery.isEmpty {
                            await viewModel.fetchWeatherForCity(city: searchQuery)
                        } else {
                            viewModel.locationManager.requestLocation()
                        }
                    }
                } else {
                    Spacer()
                    emptyStateView
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.fetchMetrics()
        }
    }
    
    // MARK: - Component Views
    
    private var searchHeader: some View {
        HStack {
            TextField("Search for a city...", text: $searchQuery)
                .padding(12)
                .background(Color.white.opacity(0.2))
                .cornerRadius(15)
                .foregroundColor(.white)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await viewModel.fetchWeatherForCity(city: searchQuery)
                    }
                }
                .overlay(
                    HStack {
                        Spacer()
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
            
            Button {
                Task { await viewModel.fetchWeatherForCity(city: searchQuery) }
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Button {
                viewModel.locationManager.requestLocation()
                searchQuery = "" // Clear search when finding location logically
            } label: {
                Image(systemName: "location.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }
    
    private func heroSection(weather: WeatherResponse) -> some View {
        VStack(spacing: 8) {
            Text(weather.name)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 2)
            
            HStack(alignment: .top) {
                Text("\(Int(weather.main.temp))")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("°C")
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 14)
            }
            .shadow(radius: 3)
            
            VStack(spacing: 5) {
                let mainCondition = weather.weather.first?.main ?? ""
                Image(systemName: viewModel.weatherIcon(for: mainCondition))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                
                Text(weather.weather.first?.description.capitalized ?? "")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func metricsGrid(weather: WeatherResponse) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricView(icon: "humidity", title: "Humidity", value: "\(Int(weather.main.humidity))%")
            MetricView(icon: "wind", title: "Wind", value: "\(String(format: "%.1f", weather.wind.speed)) m/s")
            MetricView(icon: "thermometer", title: "Feels Like", value: "\(Int(weather.main.feelsLike))°")
            // Optional addition
            MetricView(icon: "gauge", title: "Pressure", value: "Normal") // Mocked string. Add pressure to WeatherModels if required.
        }
        .padding(.vertical, 20)
        .padding(.horizontal)
    }
    
    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("5-Day Forecast")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.forecast) { item in
                        let condition = item.weather.first?.main ?? ""
                        ForecastView(item: item, icon: viewModel.weatherIcon(for: condition))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.sun.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.white.opacity(0.8))
            
            Text("Search for a city or use location to get started.")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Subviews

struct MetricView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial) // Modern glassmorphism using iOS 15+ material
        .environment(\.colorScheme, .dark) // Forces text to look vibrant directly inside thin backgrounds
        .cornerRadius(15)
    }
}

struct ForecastView: View {
    let item: ForecastItem
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text(dayFormatter.string(from: item.date))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
            
            Text("\(Int(item.main.temp))°")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .cornerRadius(15)
    }
}

private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE" // e.g. Mon, Tue
    return formatter
}()

#Preview {
    WeatherView()
}
