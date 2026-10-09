# Group Restaurant Finder

Settld is an iOS app that helps groups decide where to meet and eat. Add each person's location, discover nearby restaurants, and compare travel options on an interactive map—so planning a meetup takes less back-and-forth.

## Features

- **Group location input** — Add multiple people and enter their locations using address search or latitude/longitude coordinates.
- **Restaurant discovery** — Find restaurants with Apple MapKit local search.
- **Group-friendly suggestions** — Uses an optimal-meeting-point calculation to help identify convenient areas for a group.
- **Interactive map** — View restaurant and group-member markers together.
- **Travel routes** — Request routes and view travel information for group members.
- **Look Around previews** — Explore supported destinations with Apple's Look Around feature.
- **Saved planning state** — Remembers entered people and the map region between launches.
- **Distance preferences** — Choose kilometers or miles.
- **Onboarding and settings** — Includes an onboarding flow, app information, feedback links, legal pages, and sharing.
- **Premium subscriptions** — Uses RevenueCat to check subscription entitlements and manage subscriptions.
- **Local notifications** — Can schedule reminder notifications, subject to notification permission.

## Tech stack

- **Language:** Swift 5
- **UI:** SwiftUI
- **Maps and place search:** MapKit
- **Location data:** Core Location
- **Notifications:** UserNotifications
- **Subscription management:** RevenueCat (`purchases-ios` and RevenueCat UI)
- **Navigation helpers:** SwiftfulRouting and SwiftfulRecursiveUI
- **Project:** Xcode project (`SettleIt.xcodeproj`)

## Requirements

- A Mac with a compatible version of Xcode
- iOS 18 or later (the project includes targets configured for iOS 18 / 18.5)
- An iPhone or iOS Simulator
- Internet access for map/place search and subscription services

Some MapKit experiences, including Look Around and route results, depend on regional availability and Apple's supported data.

## Getting started

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd Settld-Group-Restaurant-Finder
   ```

   Replace `<repository-url>` with the URL of your Git repository. If you downloaded the source as a ZIP, extract it and open the project folder instead.

2. Open the Xcode project:

   ```bash
   open SettleIt.xcodeproj
   ```

3. In Xcode, select the **SettleIt** app scheme and choose an iOS Simulator or connected iPhone.

4. Allow Xcode to resolve the Swift Package Manager dependencies. The repository pins these packages in `SettleIt.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

5. Build and run with **Product → Run** (`⌘R`).

## Dependencies

The project uses Swift Package Manager for these third-party packages:

| Package | Purpose |
| --- | --- |
| [RevenueCat purchases-ios](https://github.com/RevenueCat/purchases-ios) | Subscription status and subscription management |
| [SwiftfulRouting](https://github.com/SwiftfulThinking/SwiftfulRouting) | SwiftUI navigation utilities |
| [SwiftfulRecursiveUI](https://github.com/SwiftfulThinking/SwiftfulRecursiveUI) | Reusable SwiftUI UI utilities |

Xcode should resolve the versions recorded in `Package.resolved`.

## Using the app

1. Complete the onboarding screens.
2. Open the group location input flow.
3. Add the people who are meeting. For each person, provide a name and a location using address lookup or coordinates.
4. Run the place-finding flow to search for restaurants around the group.
5. Explore the results on the map. Select a restaurant to access supported map actions, previews, or routes.
6. Open **Settings** to change the distance unit, review subscription status, read legal information, share the app, or submit feedback.

Exact screen labels and available map actions may vary with the app version and location.

## Project structure

```text
.
├── SettleIt.xcodeproj/                 # Xcode project and SwiftPM configuration
├── SettleIt/
│   ├── SettleItApp.swift               # App entry point
│   ├── MainTabView.swift               # Main app navigation
│   ├── CustomTabBarView.swift          # Custom tab bar
│   ├── OnboardingView.swift            # First-run introduction
│   ├── CoordinateInputView.swift       # Group member/location input
│   ├── OptimalMeetingPointCalculator.swift # Meeting-point calculations
│   ├── Restaurant.swift                # Place search and restaurant models/helpers
│   ├── MapSearchableView.swift          # Search and result presentation
│   ├── MapView.swift                    # Map, markers, routes, Look Around
│   ├── PersistenceService.swift         # Saved people and map region
│   ├── NotificationManager.swift        # Local notifications
│   ├── SettingsView.swift               # Preferences, links, settings
│   ├── SubscriptionManager.swift        # RevenueCat subscription state
│   ├── SubscriptionStatusView.swift     # Premium subscription UI
│   ├── AboutMeView.swift                # About/developer information
│   └── Assets.xcassets/                 # App icons and image assets
├── SettleItTests/                       # Unit-test target
└── SettleItUITests/                     # UI-test target
```

## Configuration notes

- **RevenueCat:** Subscription features use RevenueCat and the `Premium` entitlement. Configure the appropriate RevenueCat project and app credentials in the app's setup before testing purchases. Never commit private API keys or secrets to source control.
- **Apple Maps:** Place discovery, route calculations, and Look Around rely on MapKit and Apple's available map data.
- **Notifications:** The app needs user permission to deliver notifications. If permission is denied, notifications will not be scheduled.
- **App Store links:** Settings contains App Store links for sharing and reviews. Update these if the app listing changes.

No separate server or `.env` file is evident in the checked-in project structure; if you add external services, document their required configuration here.

## Tests

The repository includes `SettleItTests` and `SettleItUITests` targets. To run them in Xcode:

1. Select the **SettleIt** scheme.
2. Choose an iOS Simulator.
3. Select **Product → Test** (`⌘U`).

The checked-in test files currently contain starter/example test cases, so additional feature-specific tests are recommended.

## Contributing

Contributions and suggestions are welcome.

1. Create a branch for your change.
2. Keep changes focused and follow the existing SwiftUI code style.
3. Run the available tests in Xcode.
4. Open a pull request with a description of the change and any relevant screenshots.

For bugs or feature ideas, use the feedback/feature-request link available from the app's Settings screen.

## Privacy

The app works with location information supplied by users and uses Apple MapKit to search for places and calculate routes. Review the linked privacy policy in the app for the project's current data-handling details. Do not include personal location data, credentials, or API secrets in issues or pull requests.

## License

No license file was found in the supplied project archive. Unless a license is added to the repository, reuse and redistribution permissions are not explicitly specified.
