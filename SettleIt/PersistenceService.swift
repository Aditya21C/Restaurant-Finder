import Foundation
import MapKit

class PersistenceService {
    // A shared instance for easy access
    static let shared = PersistenceService()
    
    private let userDefaults = UserDefaults.standard
    private let peopleInputKey = "lastPeopleInput"
    private let mapRegionKey = "mapRegion"
    
    /// Saves an array of PersonInput to UserDefaults.
    func savePeople(_ people: [PersonInput]) {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(people)
            userDefaults.set(encodedData, forKey: peopleInputKey)
        } catch {
            print("Failed to save people to UserDefaults: \(error)")
        }
    }

    /// Loads an array of PersonInput from UserDefaults.
    func loadPeople() -> [PersonInput]? {
        guard let data = userDefaults.data(forKey: peopleInputKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let people = try decoder.decode([PersonInput].self, from: data)
            return people
        } catch {
            print("Failed to load people from UserDefaults: \(error)")
            return nil
        }
    }
    
    
    func saveRegion(_ region: MKCoordinateRegion) {
            let codableRegion = CodableMKCoordinateRegion(region)
            do {
                let data = try JSONEncoder().encode(codableRegion)
                userDefaults.set(data, forKey: mapRegionKey)
            } catch {
                print("Error saving map region: \(error)")
            }
        }
    func loadRegion() -> MKCoordinateRegion? {
            guard let data = userDefaults.data(forKey: mapRegionKey) else {
                return nil
            }
            do {
                let codableRegion = try JSONDecoder().decode(CodableMKCoordinateRegion.self, from: data)
                return codableRegion.asMKCoordinateRegion
            } catch {
                print("Error loading map region: \(error)")
                return nil
            }
        }
}
