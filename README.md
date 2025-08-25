# Wikipedia Explorer

A native iOS app built with SwiftUI that allows users to explore Wikipedia articles through text search and location-based discovery.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open `WikipediaExplorer.xcodeproj` in Xcode
3. Build and run (⌘+R)

## Features

### Core Functionality
- **Text Search**: Search Wikipedia articles by keyword with debounced real-time results
- **Location-Based Discovery**: Find articles about nearby places using device location
- **Dual Display**: View results in both list and interactive map formats
- **Article Details**: Shows title, thumbnail, coordinates, and links to full Wikipedia article

### Additional Features
- Search history with recent searches
- "Search This Area" when panning the map
- Comprehensive error handling with retry options
- Dark mode support

## Architecture & Design Decisions

### Technical Choices
- **MVVM with `@Observable`**: Swift 6's macro for reactive state management
- **Actor-based API Client**: Thread-safe network operations using Swift concurrency
- **Protocol-Oriented Design**: All services use protocols for testability
- **Generic `Loadable` State**: Consistent loading state management across views
- **Comprehensive Test Suite**: Mocks for all services, extensive view model testing

### Trade-offs

1. **iOS 17.0 Minimum**: Supporting iOS 17+ limits access to newer APIs and frameworks. A higher deployment target would enable additional SwiftUI enhancements and the latest testing frameworks.

2. **Simple Persistence**: Search history uses `UserDefaults` instead of Core Data, limiting to 10 recent searches.

3. **No Offline Support**: Articles aren't cached locally to keep the app lightweight.

4. **Basic UI Design**: Focused on functionality over visual polish. Used system components and standard SwiftUI styling rather than custom design.

5. **Map Annotations**: Native SwiftUI `Marker` instead of custom callouts for simplicity.

## Testing

Comprehensive test suite covering view models, API clients, error handling, and location services. Run with ⌘+U.

## API Configuration

Uses Wikipedia's public API with proper User-Agent configuration as required:
- Text search: `generator=search`
- Location search: `generator=geosearch`
