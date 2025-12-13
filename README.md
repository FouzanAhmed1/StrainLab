# StrainLab

On device wearable analytics for iOS and watchOS with Recovery, Strain, and Sleep tracking.

## Overview

StrainLab is a privacy focused fitness analytics app that calculates personalized Recovery, Strain, and Sleep scores using data from Apple Watch sensors. All processing happens on device with no backend services required.

## Features

- **Recovery Score (0-100)**: Measures how prepared your body is for strain based on HRV, resting heart rate, and sleep quality
- **Strain Score (0-21)**: Tracks cardiovascular load using heart rate zone analysis
- **Sleep Score (0-100)**: Evaluates sleep duration, efficiency, and stage quality
- **Transparency Layer**: Every score includes detailed explanations of inputs and calculations
- **7 Day Trends**: Track your metrics over time with interactive charts

## Architecture

### On Device First
- Watch app collects heart rate, HRV, and workout data
- iPhone app handles all processing and visualization
- CoreData persistence for raw and calculated data
- No cloud services or external data sharing

### Tech Stack
- SwiftUI for all UI
- HealthKit for health data
- CoreMotion for accelerometer during workouts
- WatchConnectivity for Watch to iPhone data transfer
- Swift Charts for trend visualization
- CoreData for persistence

## Project Structure

```
StrainLab/
├── StrainLabKit/           # Shared Swift Package
│   └── Sources/
│       └── StrainLabKit/
│           ├── Models/     # Domain models
│           ├── Protocols/  # Interfaces
│           └── Extensions/ # Utilities
├── StrainLab/              # iPhone App
│   ├── App/                # Entry point
│   ├── Core/
│   │   ├── HealthKit/      # HealthKit integration
│   │   ├── Persistence/    # CoreData
│   │   ├── Connectivity/   # WatchConnectivity
│   │   └── Processing/     # Score calculators
│   ├── Features/
│   │   ├── Dashboard/      # Main screen
│   │   ├── Recovery/       # Recovery detail
│   │   ├── Strain/         # Strain detail
│   │   └── Sleep/          # Sleep detail
│   └── SharedUI/
│       ├── Theme/          # Design system
│       └── Components/     # Reusable views
└── StrainLabWatch/         # Watch App
    ├── App/                # Entry point and views
    ├── DataCollection/     # HealthKit and connectivity
    └── WorkoutTracking/    # Workout sessions
```

## Score Calculations

### Recovery Score
Weighted combination of:
- HRV deviation from 7 day baseline (50%)
- Resting HR deviation from baseline (30%)
- Sleep quality score (20%)

Categories: Poor (0-33), Moderate (34-66), Optimal (67-100)

### Strain Score
Based on time in heart rate zones with exponential weights:
- Zone 1 (50-60% max HR): 0.5x
- Zone 2 (60-70%): 1x
- Zone 3 (70-80%): 2x
- Zone 4 (80-90%): 4x
- Zone 5 (90-100%): 8x

Converted to 0-21 scale using logarithmic function

### Sleep Score
Weighted combination of:
- Duration vs personalized sleep need (40%)
- Sleep efficiency (35%)
- Stage quality (deep ~20%, REM ~25% ideal) (25%)

## Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 15.0+
- Apple Watch for full functionality

## Setup

1. Clone the repository
2. Open in Xcode (File > Open > select folder)
3. Select the StrainLab scheme
4. Build and run on device (HealthKit requires physical device)

## Privacy

StrainLab processes all health data on device. No data is sent to external servers. The app requests only the minimum required HealthKit permissions:
- Heart rate (read)
- Heart rate variability (read)
- Resting heart rate (read)
- Sleep analysis (read)
- Workouts (read/write)

## License

MIT License
