# Real-Time Location Alert Application

A cross-platform Flutter mobile application designed for real-time destination proximity tracking and alerts on Android and iOS. The app continuously tracks user movement, calculates geodesic distance to a target destination, applies GPS noise protection, and triggers single-firing 100-meter warning and arrival alerts with sound, vibration, and system notifications—even in the background.

---

## Key Features

- 📍 **Live Location & Interactive Map**: Built using `flutter_map` with OpenStreetMap raster tiles, high-accuracy GPS tracking, accuracy circles, and recenter map controls.
- 🔍 **Destination Search & Map Pinning**: Search places using Nominatim geocoding or select any location directly by tapping the interactive map.
- 🗺️ **Routing & Directions**: Calculates driving routes and polylines via OSRM, with automatic offline straight-line geodesic polyline fallback.
- ⚠️ **100-Meter Proximity Alert**: Triggers a single-firing warning dialog, system notification, sound, and vibration pattern when within 100 meters (configurable).
- 🔔 **Destination Arrival Alert**: Triggers an arrival alert, persistent notification, and multi-burst vibration pattern when entering the arrival radius (20 meters by default), automatically stopping active stream tracking.
- 🛡️ **GPS Noise Protection**: Median filtering and rolling buffer verification to prevent false alert triggers caused by temporary GPS inaccuracy spikes.
- 📱 **Background Execution**: Configured for Android Foreground Service (`AndroidSettings.foregroundNotificationConfig`) and iOS Background Location Mode (`UIBackgroundModes: location`).
- ⚙️ **Customizable Settings**: Adjust warning distance (30m–2000m), arrival distance (5m–200m), toggle sound, vibration, system notifications, and dark theme.
- 🧪 **Unit & Widget Tests**: 100% test coverage for geodesic distance calculations, GPS noise filter median logic, alert state transitions, and UI components.

---

## System Architecture

```text
lib/
├── main.dart                          # App entrypoint & ProviderScope initialization
├── app/
│   ├── app.dart                       # MaterialApp setup with dark/light themes
│   └── theme.dart                     # Modern Material 3 dark and light design system
├── core/
│   ├── constants/                     # App & location constants
│   ├── errors/                        # Custom Failure exception models
│   ├── services/                      # StorageService (SharedPreferences)
│   └── utils/                         # DistanceCalculator (Haversine) & GpsNoiseFilter
├── features/
│   ├── destination/                   # Destination search service, screens & Riverpod state
│   ├── location/                      # Geolocator location service, accuracy & stream controller
│   ├── map/                           # Interactive map screen, OSRM routing & trip bottom sheet
│   ├── notifications/                 # LocalNotificationService with sound & vibration
│   ├── settings/                      # Settings controller, model & settings screen
│   └── trip/                          # Trip model, StateNotifier, alert dialogs & lifecycle
└── shared/
    └── widgets/                       # StatusBadge, CustomButton, CustomTextField
```

---

## Development & Setup Instructions

### Prerequisites
- **Flutter SDK**: 3.47.2 or compatible (Dart 3.13.2+)
- **Android Studio / Xcode** for mobile builds.

### 1. Clone & Install Dependencies
```bash
cd my_app
flutter pub get
```

### 2. Run the Application
```bash
# Run on connected Android device/emulator
flutter run -d android

# Run on iOS simulator
flutter run -d ios
```

---

## Background Location Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)
The app declares the following required permissions:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `POST_NOTIFICATIONS`
- `VIBRATE`

*Note: On Android 10+ (API 29+), users must select "Allow all the time" in location permission settings to enable background tracking.*

### iOS (`ios/Runner/Info.plist`)
The app defines location usage keys and background execution modes:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`
- `UIBackgroundModes`: `location`

---

## Running Tests

Execute the complete test suite (unit tests for Haversine math, GPS noise filter median calculations, trip state transition rules, and UI widget tests):

```bash
flutter test
```

Perform static code analysis:

```bash
flutter analyze
```

---

## API Key Security

- OpenStreetMap and OSRM services are preconfigured for immediate open-source usage without requiring an API key.
- If integrating Google Maps or Directions API for production, store API keys in environment variables or platform configurations (`AndroidManifest.xml` / `Info.plist`) and add key configuration files to `.gitignore`. Never commit raw API secret keys to public repositories.
