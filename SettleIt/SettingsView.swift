import SwiftUI

// MARK: - New Enum for Distance Units
// This enum defines the distance unit options and makes them easy to store and use.
enum DistanceUnit: String, CaseIterable, Identifiable {
    case kilometers = "Kilometers"
    case miles = "Miles"
    
    // Conformance to Identifiable for use in ForEach
    var id: Self { self }
}


// MARK: - Main Settings View Logic
enum SettingsDestination: Identifiable, Hashable {
    case subscription
    case aboutMe

    var id: SettingsDestination { self }

    @ViewBuilder
    var view: some View {
        switch self {
        case .subscription:
            SubscriptionStatusView()
        case .aboutMe:
            AboutMayukhView()
        }
    }
    
    var navigationTitle: String {
        switch self {
        case .subscription:
            return "Subscription"
        case .aboutMe:
            return "About Me"
        }
    }
}

struct SettingsView: View {
    @Environment(\.openURL) var openURL
    @State private var path: [SettingsDestination] = []

    // NEW: Persisted state for the user's selected distance unit.
    // The choice will be saved and available in any other view.
    @AppStorage("distanceUnit") private var distanceUnit: DistanceUnit = .kilometers
    
    // NEW: URLs for sharing and rating. Replace with your actual App Store URLs.
    private let appShareURL = URL(string: "https://apps.apple.com/app/id6748634598")!
    private let appReviewURL = URL(string: "https://apps.apple.com/app/id6748634598?action=write-review")!


    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section(header: Text("Account")) {
                    NavigationLink(value: SettingsDestination.subscription) {
                        rowContent(title: "Subscription", systemImage: "creditcard.fill", color: .blue)
                    }
                }
                
                // NEW: Section for user preferences like distance units.
                Section(header: Text("Preferences")) {
                    Picker("Distance Unit", selection: $distanceUnit) {
                        ForEach(DistanceUnit.allCases) { unit in
                            Text(unit.rawValue)
                        }
                    }
                    .pickerStyle(.segmented) // A common style for this type of control.
                }

                Section(header: Text("Legal")) {
                    Button(action: {
                        guard let url = URL(string: "https://sites.google.com/view/settld-tos/home") else { return }
                        openURL(url)
                    }) {
                        fullRowContent(title: "Terms of Service", systemImage: "doc.text.fill", color: .gray)
                    }
                    
                    Button(action: {
                        guard let url = URL(string: "https://sites.google.com/view/settld-privacypolicy/home") else { return }
                        openURL(url)
                    }) {
                        fullRowContent(title: "Privacy Policy", systemImage: "lock.shield.fill", color: .green)
                    }
                }

                // RENAMED & EXPANDED: Section for support, feedback, and sharing.
                Section(header: Text("Support & Feedback")) {
                    // NEW: ShareLink presents a share sheet. Its label is our custom row.
                    ShareLink(item: appShareURL) {
                        fullRowContent(title: "Share Settld", systemImage: "square.and.arrow.up.fill", color: .yellow)
                    }
                    
                    // NEW: Button to open the App Store review page.
                    Button(action: { openURL(appReviewURL) }) {
                        fullRowContent(title: "Rate Settld", systemImage: "face.smiling.inverse", color: .teal)
                    }
                    
                    Button(action: {
                        guard let url = URL(string: "https://featurerequestsforsettld.featurebase.app") else { return }
                        openURL(url)
                    }) {
                        fullRowContent(title: "Feedback/Feature Requests", systemImage: "list.bullet.clipboard.fill", color: .purple)
                    }

                    NavigationLink(value: SettingsDestination.aboutMe) {
                        rowContent(title: "About Me", systemImage: "person.fill", color: .orange)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsDestination.self) { destination in
                destination.view
                    .navigationTitle(destination.navigationTitle)
            }
        }
        .preferredColorScheme(.dark)
    }

    // Helper for basic row content (used by NavigationLink)
    private func rowContent(title: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .foregroundColor(.primary) // Ensures text color is correct inside links
        }
    }
    
    // Helper for a full row that includes a chevron (used by Button and ShareLink)
    private func fullRowContent(title: String, systemImage: String, color: Color) -> some View {
        HStack {
            rowContent(title: title, systemImage: systemImage, color: color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
