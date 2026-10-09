//
//  MapView.swift
//

import SwiftUI
import MapKit

// This struct defines the main map view for the application.
struct MapView: View {
    @AppStorage("distanceUnit") private var distanceUnit: DistanceUnit = .kilometers
    // MARK: - Input Properties
    let restaurants: [MKMapItem]
    let people: [PersonInput]
    
    // MARK: - State Properties
    @State private var selectedRestaurant: MKMapItem?
    @State private var routes: [MKRoute] = [] // For the "Go" button polylines
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // State for UI sheets
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLookAroundSheetPresented: Bool = false
    
    // State to hold calculated travel info for the sheet
    @State private var travelInfo: [PersonInput: MKRoute] = [:]
    
    // State to toggle between native sheet and custom buttons
    @State private var isFunctionsModeEnabled: Bool = false

    // MARK: - Body
    var body: some View {
        ZStack {
            // The main Map view provided by SwiftUI and MapKit.
            Map(position: $cameraPosition, selection: $selectedRestaurant) {
                
                // MARK: Restaurant Markers
                ForEach(restaurants, id: \.self) { restaurant in
                    if isFunctionsModeEnabled {
                        Marker(item: restaurant)
                    } else {
                        Marker(item: restaurant)
                            .mapItemDetailSelectionAccessory()
                    }
                }
                
                // MARK: People Markers
                ForEach(people) { person in
                    if let coordinate = person.coordinate {
                        Annotation(person.name, coordinate: coordinate) {
                            personMarker
                        }
                    }
                }
                
                // MARK: Route Polylines
                ForEach(routes, id: \.self) { route in
                    MapPolyline(route.polyline)
                        .stroke(.red, lineWidth: 6)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            
            // This VStack overlays the controls at the bottom of the screen.
            VStack {
                Spacer() // Pushes content to the bottom
                
                if isFunctionsModeEnabled, selectedRestaurant != nil {
                    bottomActionButtons
                        .padding(.bottom, 8)
                }
                
                functionsToggleButton
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
            .shadow(radius: 10)
        }
        .onAppear(perform: setupMapCamera)
        .onChange(of: restaurants) { _, _ in setupMapCamera() }
        .onChange(of: selectedRestaurant) {
            // When selection changes, clear all previous contextual data.
            selectRestaurant()
        }
        .sheet(isPresented: $isLookAroundSheetPresented, content: lookAroundPreviewSheet)
    }
}

// MARK: - View Components
private extension MapView {
    
    /// The view for a person's location marker.
    var personMarker: some View {
        Image(systemName: "person.circle.fill")
            .font(.title)
            .foregroundStyle(.blue)
            .background(.white)
            .clipShape(Circle())
            .shadow(radius: 3)
    }
    
    /// A view containing the action buttons ("Look", "Go").
    var bottomActionButtons: some View {
        HStack(spacing: 12) {
            // This button now presents the combined Look Around and Travel Info sheet.
            ActionButton(title: "Look", systemImage: "binoculars.fill", backgroundColor: .green) {
                isLookAroundSheetPresented = true
            }
            
            ActionButton(title: "Go", systemImage: "arrow.triangle.turn.up.right.diamond", backgroundColor: .blue) {
                Task { await fetchAllRoutesForPolyline() }
            }
        }
        .transition(.scale.animation(.easeInOut))
    }
    
    /// The persistent button to toggle the functions mode.
    var functionsToggleButton: some View {
        Button(action: {
            // Wrap the state change in a withAnimation block
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isFunctionsModeEnabled.toggle()
            }
            
            if !isFunctionsModeEnabled {
                selectedRestaurant = nil
            }
        }) {
            Label(
                isFunctionsModeEnabled ? "Functions" : "Info",
                systemImage: isFunctionsModeEnabled ? "slider.horizontal.3" : "info.circle"
            )
            .font(.headline.bold())
            .foregroundStyle(.white)
            .padding()
            // Use a ternary operator for cleaner background logic
            .background(isFunctionsModeEnabled ? Color.purple : Color.teal)
            .clipShape(Capsule())
            // The animation is now triggered by the state change, not attached to the view
        }
        .buttonStyle(NoHighlightButtonStyle())
    }
    
    /// MODIFIED: The content displayed inside the Look Around sheet, now with travel info.
    func lookAroundPreviewSheet() -> some View {
        VStack {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedRestaurant?.name ?? "Unknown Place").font(.title2.bold())
                    Text(selectedRestaurant?.placemark.title ?? "").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { isLookAroundSheetPresented = false }
            }
            .padding([.horizontal, .top])

            // Travel Info Section
            List {
                Section(header: Text("Travel Information").font(.headline)) {
                    if travelInfo.isEmpty {
                        ProgressView("Calculating routes...")
                    } else {
                        // Iterate over the sorted travel info to display it.
                        ForEach(travelInfo.sorted(by: { $0.value.expectedTravelTime < $1.value.expectedTravelTime }), id: \.key) { person, route in
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundStyle(.blue)
                                Text(person.name)
                                Spacer()
                                // Using route.expectedTravelTime and route.distance as requested
                                Text("\(formatTravelTime(route.expectedTravelTime)) / \(formatDistance(route.distance))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .frame(height: 180) // Constrain the height of the travel info list

            // Look Around Preview Section
            if let scene = lookAroundScene {
                LookAroundPreview(initialScene: scene)
                    .overlay(alignment: .bottom) {
                        Text("Look Around")
                            .foregroundStyle(.white)
                            .font(.caption.bold())
                            .padding(6)
                            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            .padding(8)
                    }
            } else {
                ContentUnavailableView("Apple Look Around imagery is not available for this location. Try another nearby place.", systemImage: "eye.slash")
            }
        }
        .onAppear {
            Task {
                // Fetch both Look Around and Travel Info data when the sheet appears.
                await fetchLookAroundScene()
                await fetchTravelInfo()
            }
        }
        .presentationDetents([.large]) // Use .large to ensure all content is visible
        .presentationDragIndicator(.visible)
    }
}


// MARK: - Custom Button Style & Reusable Views
private struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.bold())
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .clipShape(Capsule())
        }
    }
}


// MARK: - Functions & Logic
private extension MapView {
    
    /// Clears old contextual data when a new restaurant is selected.
    func selectRestaurant() {
        self.routes.removeAll()
        self.travelInfo.removeAll()
        self.lookAroundScene = nil
    }
    
    /// Fetches the Look Around scene for the selected restaurant.
    func fetchLookAroundScene() async {
        guard let selectedRestaurant, lookAroundScene == nil else { return }
        let request = MKLookAroundSceneRequest(coordinate: selectedRestaurant.placemark.coordinate)
        self.lookAroundScene = try? await request.scene
    }
    
    /// Configures the initial camera position.
    func setupMapCamera() {
        let allCoordinates = restaurants.map { $0.placemark.coordinate } + people.compactMap { $0.coordinate }
        
        if allCoordinates.isEmpty {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 22.5726, longitude: 88.3639),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            ))
        } else {
            cameraPosition = .automatic
        }
    }
    
    /// Fetches route information to display in the sheet.
    func fetchTravelInfo() async {
        guard let selectedRestaurant, !people.isEmpty else { return }
        let validPeople = people.filter { $0.coordinate != nil }
        guard !validPeople.isEmpty else { return }
        
        var calculatedInfo: [PersonInput: MKRoute] = [:]
        
        await withTaskGroup(of: (PersonInput, MKRoute)?.self) { group in
            for person in validPeople {
                group.addTask {
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: person.coordinate!))
                    request.destination = selectedRestaurant
                    request.transportType = .automobile
                    
                    if let result = try? await MKDirections(request: request).calculate(), let route = result.routes.first {
                        return (person, route)
                    }
                    return nil
                }
            }
            
            for await result in group {
                if let (person, route) = result {
                    calculatedInfo[person] = route
                }
            }
        }
        
        self.travelInfo = calculatedInfo
    }
    
    /// Fetches routes for drawing polylines on the map.
    func fetchAllRoutesForPolyline() async {
        // This function is now distinct from fetchTravelInfo and only handles map polylines
        guard let selectedRestaurant, !people.isEmpty else { return }
        
        var calculatedRoutes: [MKRoute] = []
        for person in people where person.coordinate != nil {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: person.coordinate!))
            request.destination = selectedRestaurant
            if let result = try? await MKDirections(request: request).calculate(), let route = result.routes.first {
                calculatedRoutes.append(route)
            }
        }
        self.routes = calculatedRoutes
        updateCameraToShowRoutes(routes: calculatedRoutes)
    }
    
    /// Updates the camera to fit all calculated routes.
    func updateCameraToShowRoutes(routes: [MKRoute]) {
        guard !routes.isEmpty else { return }
        let totalBoundingRect = routes.reduce(MKMapRect.null) { $0.union($1.polyline.boundingMapRect) }
        withAnimation(.easeOut) {
            self.cameraPosition = .rect(totalBoundingRect)
        }
    }
    
    // MARK: - Formatters
    
    private func formatTravelTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: time) ?? "N/A"
    }

    private func formatDistance(_ distance: CLLocationDistance) -> String {
        // distance is always in meters from MapKit
        let distanceInMeters = distance

        switch distanceUnit {
        case .kilometers:
            // Convert meters to kilometers
            let kilometers = distanceInMeters / 1000.0
            // Format to one decimal place, e.g., "5.2 km"
            return String(format: "%.1f km", kilometers)
            
        case .miles:
            // Convert meters to miles (1 meter = 0.000621371 miles)
            let miles = distanceInMeters * 0.000621371
            // Format to one decimal place, e.g., "3.2 mi"
            return String(format: "%.1f mi", miles)
        }
    }
}

// MARK: - Model Extensions
extension PersonInput {
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension PersonInput: Hashable {
    public static func == (lhs: PersonInput, rhs: PersonInput) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
