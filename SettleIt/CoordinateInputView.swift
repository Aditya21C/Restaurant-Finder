import SwiftUI
import MapKit
import Combine

// MARK: - Supporting Types & Services

enum InputType: String, CaseIterable, Identifiable {
    case addressLookup = "Address"
    case coordinates = "Coordinates"
    var id: Self { self }
}

struct PersonInput: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var latitude: Double?
    var longitude: Double?

    init(id: UUID = UUID(), name: String = "", latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    private var completer: MKLocalSearchCompleter
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
    }
    
    func updateQueryFragment(_ query: String) {
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results.filter { !$0.title.isEmpty }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("MKLocalSearchCompleter Error: \(error.localizedDescription)")
    }
}


// MARK: - Main View

struct CoordinateInputView: View {
    @Environment(\.dismiss) var dismiss
    let onCompletion: ([PersonInput]) -> Void

    // State for final data
    @State private var names: [String]
    @State private var lats: [String]
    @State private var lons: [String]
    
    // State for UI control
    @State private var inputTypes: [InputType]
    @State private var activeSearchIndex: Int? = nil
    @State private var searchQueries: [String]
    
    @StateObject private var locationSearchService = LocationSearchService()

    private var count: Int { names.count }
    
    private var allValid: Bool {
        for i in 0..<count {
            let name = names[i].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return false }
            
            guard
                let lat = Double(lats[i].replacingOccurrences(of: ",", with: ".")),
                let lon = Double(lons[i].replacingOccurrences(of: ",", with: "."))
            else { return false }
            
            guard (-90...90).contains(lat), (-180...180).contains(lon) else { return false }
        }
        return true
    }
    
    init(onCompletion: @escaping ([PersonInput]) -> Void) {
        self.onCompletion = onCompletion
        let initialCount = 2
        _names = State(initialValue: Array(repeating: "", count: initialCount))
        _lats = State(initialValue: Array(repeating: "", count: initialCount))
        _lons = State(initialValue: Array(repeating: "", count: initialCount))
        _inputTypes = State(initialValue: Array(repeating: .addressLookup, count: initialCount))
        _searchQueries = State(initialValue: Array(repeating: "", count: initialCount))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                        Section {
                            numberOfPeoplePicker()
                            ForEach(0..<count, id: \.self) { i in
                                personInputCard(for: i)
                            }
                            findPlacesButton()
                        } header: {
                            viewHeader()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundStyle(.black)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Subviews & Helper Functions
    
    @ViewBuilder
    private func personInputCard(for i: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Person \(i + 1) Name", text: $names[i])
                    .font(.headline)
                
                Picker("Input Type", selection: $inputTypes[i]) {
                    ForEach(InputType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            
            switch inputTypes[i] {
            case .addressLookup:
                addressLookupField(for: i)
            case .coordinates:
                coordinateFields(for: i)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func addressLookupField(for i: Int) -> some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)

                TextField("Search address...", text: $searchQueries[i], onEditingChanged: { isEditing in
                    // ✅ FIX: Use onEditingChanged to reliably set the active index
                    // when the user taps into the text field.
                    if isEditing {
                        self.activeSearchIndex = i
                    }
                })
                .onChange(of: searchQueries[i]) { newQuery in
                    if activeSearchIndex == i {
                        locationSearchService.updateQueryFragment(newQuery)
                    }
                }
            }
            
            if activeSearchIndex == i && !locationSearchService.completions.isEmpty {
                List(locationSearchService.completions, id: \.self) { completion in
                    Button(action: { selectAddress(completion, for: i) }) {
                        VStack(alignment: .leading) {
                            Text(completion.title).foregroundColor(.primary)
                            Text(completion.subtitle).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    @ViewBuilder
    private func coordinateFields(for i: Int) -> some View {
        HStack {
            TextField("Latitude", text: $lats[i])
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
            
            TextField("Longitude", text: $lons[i])
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private func numberOfPeoplePicker() -> some View {
        VStack(alignment: .leading) {
            Text("Number of People:")
                .font(.headline)
                .padding(.horizontal)
            Picker("", selection: Binding(
                get: { count },
                set: { newCount in
                    let difference = newCount - count
                    if difference > 0 {
                        let newItemsCount = difference
                        names.append(contentsOf: Array(repeating: "", count: newItemsCount))
                        lats.append(contentsOf: Array(repeating: "", count: newItemsCount))
                        lons.append(contentsOf: Array(repeating: "", count: newItemsCount))
                        inputTypes.append(contentsOf: Array(repeating: .addressLookup, count: newItemsCount))
                        searchQueries.append(contentsOf: Array(repeating: "", count: newItemsCount))
                    } else if difference < 0 {
                        let removalCount = -difference
                        names.removeLast(removalCount)
                        lats.removeLast(removalCount)
                        lons.removeLast(removalCount)
                        inputTypes.removeLast(removalCount)
                        searchQueries.removeLast(removalCount)
                    }
                }
            )) {
                ForEach(2..<7) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
    
    private func findPlacesButton() -> some View {
        Button {
            let people = (0..<count).map { idx -> PersonInput in
                return PersonInput(
                    name: names[idx].trimmingCharacters(in: .whitespaces),
                    latitude: Double(lats[idx].replacingOccurrences(of: ",", with: "."))!,
                    longitude: Double(lons[idx].replacingOccurrences(of: ",", with: "."))!
                )
            }
            onCompletion(people)
        } label: {
            Text("Find Places")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(allValid ? Color.black : Color.gray.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!allValid)
        .padding([.horizontal, .top])
    }
    
    private func viewHeader() -> some View {
        Text("Find Places for Your Group")
            .font(.title.bold())
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white)
    }

    private func selectAddress(_ completion: MKLocalSearchCompletion, for index: Int) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            guard index < self.lats.count else { return }
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                print("Error getting coordinates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.lats[index] = String(coordinate.latitude)
            self.lons[index] = String(coordinate.longitude)
            
            self.searchQueries[index] = completion.title
            self.locationSearchService.completions = []
            self.activeSearchIndex = nil
            
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


// MARK: - Preview

struct CoordinateInputView_Previews: PreviewProvider {
    static var previews: some View {
        CoordinateInputView { people in
            print("Got:", people)
        }
    }
}
