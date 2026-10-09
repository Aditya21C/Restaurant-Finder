import Foundation
import MapKit
import Contacts

class LocalSearchService: NSObject, ObservableObject {
    
    // The main function now includes a distance filter.
    func fetchPlaces(for location: CLLocationCoordinate2D) async throws -> [MKMapItem] {
        
        // Your excellent dynamic search logic is preserved.
        var mapItems = try await search(for: location, radius: 3000)
        
        if mapItems.count < 10 {
            print("Initial search found only \(mapItems.count) places. Expanding search radius to 5km...")
            mapItems = try await search(for: location, radius: 5000)
        }
        
        // ✅ ADDED: Filter out results that are unreasonably far away.
        let searchLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let maxDistanceInMeters: CLLocationDistance = 250000 // 250 kilometers
        
        let nearbyItems = mapItems.filter { item in
            guard let itemLocation = item.placemark.location else {
                // If the item has no location, discard it.
                return false
            }
            // Calculate the distance from the search center to the result.
            let distance = searchLocation.distance(from: itemLocation)
            // Keep the item only if it's within our maximum allowed distance.
            return distance <= maxDistanceInMeters
        }
        
        // If the *filtered* list is empty, throw an error.
        if nearbyItems.isEmpty {
            throw NSError(domain: "com.yourapp.search", code: 404, userInfo: [NSLocalizedDescriptionKey: "No restaurants found nearby, even with a wider search."])
        }
        
        // Return a capped number of the nearby results.
        return Array(nearbyItems.prefix(15))
    }
    
    // This private helper function is perfect as-is.
    private func search(for location: CLLocationCoordinate2D, radius: CLLocationDistance) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.restaurant])
        request.naturalLanguageQuery = "restaurant"
        
        let region = MKCoordinateRegion(center: location, latitudinalMeters: radius, longitudinalMeters: radius)
        request.region = region
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems
    }
    
    // This helper function is also fine as-is.
    func formatAddress(from placemark: MKPlacemark) -> String {
        guard let postalAddress = placemark.postalAddress else {
            return [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality, placemark.administrativeArea, placemark.postalCode]
                .compactMap { $0 }
                .joined(separator: ", ")
        }
        let formatter = CNPostalAddressFormatter()
        return formatter.string(from: postalAddress).replacingOccurrences(of: "\n", with: ", ")
    }
}

/// A Codable-compliant wrapper for MKCoordinateRegion.
struct CodableMKCoordinateRegion: Codable {
    let centerLatitude: CLLocationDegrees
    let centerLongitude: CLLocationDegrees
    let spanLatitudeDelta: CLLocationDegrees
    let spanLongitudeDelta: CLLocationDegrees

    // Initialize from a standard MKCoordinateRegion
    init(_ region: MKCoordinateRegion) {
        self.centerLatitude = region.center.latitude
        self.centerLongitude = region.center.longitude
        self.spanLatitudeDelta = region.span.latitudeDelta
        self.spanLongitudeDelta = region.span.longitudeDelta
    }

    // Computed property to convert back to an MKCoordinateRegion
    var asMKCoordinateRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: spanLatitudeDelta, longitudeDelta: spanLongitudeDelta)
        )
    }
}
