import SwiftUI
import MapKit

struct MapSearchableView: View {
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selection: MKMapItem?
    @State private var position: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    
    // Toggle between Info Sheet (false) and Look Around (true)
    @State private var isFunctionsModeEnabled: Bool = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLookAroundFullScreenPresented: Bool = false
    
    var body: some View {
        ZStack {
            Map(position: $position, selection: $selection) {
                ForEach(searchResults, id: \.self) { item in
                    if isFunctionsModeEnabled {
                        Marker(item: item) // Look Around mode → plain marker
                    } else {
                        Marker(item: item) // Info Sheet mode → accessory
                            .mapItemDetailSelectionAccessory()
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            
            VStack {
                // Search UI
                HStack {
                    TextField("Search for anything you like!", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: performSearch) {
                        Image(systemName: "magnifyingglass")
                            .padding(.horizontal, 8)
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding()
                .background(.thinMaterial)
                
                Spacer()
                
                // Mode Toggle Button (Always Opaque)
                PressableButton(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isFunctionsModeEnabled.toggle()
                    }
                    if !isFunctionsModeEnabled { selection = nil }
                }) {
                    Label(
                        isFunctionsModeEnabled ? "Look Around Mode" : "Info Mode",
                        systemImage: isFunctionsModeEnabled ? "binoculars.fill" : "info.circle"
                    )
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .padding()
                    .background(isFunctionsModeEnabled ? Color.purple : Color.teal)
                    .clipShape(Capsule())
                }
            }
            .padding(.bottom, 100)
        }
        .onAppear(perform: restoreSavedRegion)
        .onMapCameraChange(frequency: .onEnd) { context in
            self.visibleRegion = context.region
            PersistenceService.shared.saveRegion(context.region)
        }
        .onChange(of: searchResults) {
            if !searchResults.isEmpty {
                position = .automatic
            }
        }
        .onChange(of: selection) {
            guard isFunctionsModeEnabled, let _ = selection else { return }
            lookAroundScene = nil
            Task {
                await fetchLookAroundScene()
                // Always present full screen, even if no preview available
                isLookAroundFullScreenPresented = true
            }
        }
        .fullScreenCover(isPresented: $isLookAroundFullScreenPresented) {
            lookAroundFullScreen()
        }
    }
    
    // MARK: - Look Around Full Screen
    private func lookAroundFullScreen() -> some View {
        NavigationView {
            Group {
                if let scene = lookAroundScene {
                    LookAroundPreview(initialScene: scene)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Look Around Preview")
                            .font(.title2.bold())
                        Text("Apple Look Around imagery is not available for this location. Try another nearby place.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle(selection?.name ?? "Unknown Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isLookAroundFullScreenPresented = false }
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    private func fetchLookAroundScene() async {
        guard let selection else { return }
        let request = MKLookAroundSceneRequest(coordinate: selection.placemark.coordinate)
        if let scene = try? await request.scene {
            self.lookAroundScene = scene
        } else {
            self.lookAroundScene = nil // ensures fallback view shows
        }
    }

    // MARK: - Helpers
    private func restoreSavedRegion() {
        if let savedRegion = PersistenceService.shared.loadRegion() {
            self.position = .region(savedRegion)
            self.visibleRegion = savedRegion
        } else {
            let defaultRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
            self.position = .region(defaultRegion)
            self.visibleRegion = defaultRegion
        }
    }
    
    private func performSearch() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        guard let region = visibleRegion else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                if let error = error { print("Error during search: \(error.localizedDescription)") }
                return
            }
            DispatchQueue.main.async {
                self.searchResults = Array(response.mapItems.prefix(15))
            }
        }
    }
}

//
// MARK: - PressableButton (No Opacity Change While Holding)
//
struct PressableButton<Label: View>: View {
    var action: () -> Void
    var label: () -> Label
    
    @GestureState private var isPressed = false
    
    var body: some View {
        label()
            .scaleEffect(isPressed ? 0.97 : 1.0) // slight scale on press
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
                    .onEnded { _ in
                        action()
                    }
            )
    }
}
