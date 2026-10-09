import SwiftUI
import SwiftfulRouting
import MapKit

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showInputSheet: Bool = false
    
    // State properties to hold data for the map
    @State private var restaurants: [MKMapItem] = []
    @State private var people: [PersonInput] = []
    
    // State to show a loading indicator on launch
    @State private var isFetchingOnLaunch: Bool = true
    
    // The service to perform searches.
    @State private var localSearchService = LocalSearchService()

    @Namespace private var animationNamespace

    var body: some View {
        ZStack {
            // Main Content
            VStack {
                switch selectedTab {
                case .home:
                    if isFetchingOnLaunch {
                        ProgressView("Loading Your Map...")
                    } else if people.isEmpty {
                        // Show a welcome/empty state view if there's no saved data
                        ContentUnavailableView("Welcome to Settld", systemImage: "map.circle", description: Text("Tap the '+' button to start a new search."))
                    }
                    else {
                        MapView(restaurants: restaurants, people: people)
                    }
                case .add:
                    EmptyView()
                case .search:
                    MapSearchableView()
                case .settings:
                    SettingsView()
                }
            }

            // Custom Tab Bar Overlay
            VStack {
                Spacer()
                CustomTabBarView(
                    selectedTab: $selectedTab,
                    animationNamespace: animationNamespace,
                    onAddButtonTapped: {
                        showInputSheet = true
                    }
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showInputSheet) {
            RouterView { _ in
                CoordinateInputView { fetchedPeople in
                    // This block is the "brain" of the operation.
                    Task {
                        // 1. Set the people data from the input form.
                        self.people = fetchedPeople
                        
                        // 2. Use that data to fetch restaurants.
                        await fetchRestaurants(for: fetchedPeople)
                        
                        // 3. Update the UI.
                        self.showInputSheet = false
                        self.selectedTab = .home
                    }
                }
            }
        }
        .task {
            // This task runs once when the view first appears to load the last search.
            NotificationManager.shared.requestAuthorizationAndSchedule()
            await fetchLastSavedSearch()
            isFetchingOnLaunch = false
        }
    }
    
    /// This function now saves the people data after a successful search.
    private func fetchRestaurants(for peopleToSearch: [PersonInput]) async {
        guard let optimalCoordinate = OptimalMeetingPointCalculator.calculate(for: peopleToSearch) else {
            self.restaurants = []
            return
        }
        
        let searchCoordinate = CLLocationCoordinate2D(
            latitude: optimalCoordinate.latitude,
            longitude: optimalCoordinate.longitude
        )
        
        do {
            let fetchedRestaurants = try await localSearchService.fetchPlaces(for: searchCoordinate)
            self.restaurants = fetchedRestaurants
            
            // ✅ ADDED: Save the successful search to UserDefaults.
            // This is the key to making the location persist.
            PersistenceService.shared.savePeople(peopleToSearch)
            
        } catch {
            print("Failed to fetch restaurants: \(error.localizedDescription)")
            self.restaurants = [] // Clear restaurants on failure
        }
    }
    
    /// This function is updated to use the new fetchRestaurants helper.
    private func fetchLastSavedSearch() async {
        guard let savedPeople = PersistenceService.shared.loadPeople(), !savedPeople.isEmpty else {
            self.people = []
            return
        }
        
        self.people = savedPeople
        await fetchRestaurants(for: savedPeople)
    }
}
