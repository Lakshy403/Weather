# Modern iOS Weather Application

This folder contains the complete Swift source code for your modern iOS Weather app. 

## Requirements
- Xcode 15 or later
- iOS 16.0+
- An OpenWeatherMap API Key

## Setup Instructions

1. **Create a New Xcode Project**
   - Open Xcode and select **Create a new Xcode project**.
   - Choose **App** under the iOS tab.
   - Name the product (e.g., "WeatherApp").
   - Interface: **SwiftUI**.
   - Language: **Swift**.
   - Save it to an easy-to-find location.

2. **Add Source Files**
   - Drag and drop the following files into your new Xcode Project navigator (the left panel):
     - `WeatherModels.swift`
     - `WeatherService.swift`
     - `LocationManager.swift`
     - `WeatherViewModel.swift`
     - `WeatherView.swift`
   - Make sure "Copy items if needed" is checked.
   - You can replace your existing `ContentView.swift` with the minimal version provided.

3. **Add Location Permissions (IMPORTANT)**
   - To use CoreLocation, you must ask the user for permission.
   - Go to your Project Target settings -> **Info** tab.
   - Add a new Custom iOS Target Property: 
     - Key: `Privacy - Location When In Use Usage Description`
     - Value: *"We need your location to show the local weather."*

4. **Insert Your API Key**
   - Open `WeatherService.swift`.
   - Locate the line `private let apiKey = "YOUR_API_KEY_HERE"`.
   - Replace `"YOUR_API_KEY_HERE"` with your actual OpenWeatherMap API key (from [openweathermap.org](https://openweathermap.org/api)).

5. **Run the App**
   - Select a Simulator or your physical iOS device.
   - Hit **Cmd + R** to build and run.
   - The app features dynamic gradient backgrounds seamlessly utilizing `.ultraThinMaterial` for beautiful glassmorphism.
