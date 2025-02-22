import SwiftUI
import MapKit
import CoreLocation

struct LocationPicker: View {
    @Binding var selectedLocation: TodoItem.Location?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search or Enter Address", text: $searchText)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                List {
                    if locationManager.authorizationStatus == .authorizedWhenInUse ||
                       locationManager.authorizationStatus == .authorizedAlways {
                        if let location = locationManager.location {
                            Button {
                                selectCurrentLocation(location)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "location.north.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.gray)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Current Location")
                                            .font(.headline)
                                        Text(locationManager.currentAddress ?? "Fetching address...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            selectLocation(item)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "")
                                        .font(.headline)
                                    if let address = formatAddress(item.placemark) {
                                        Text(address)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Empty state for no search results
                    if searchText.isEmpty {
                        Text("Start typing to search for locations.")
                            .foregroundColor(.gray)
                            .padding()
                    } else if searchResults.isEmpty {
                        Text("No locations found for '\(searchText)'. Please try a different search.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
        }
        .onChange(of: searchText) { _ in
            searchLocations()
        }
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        searchRequest.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else {
                searchResults = []
                return
            }
            
            searchResults = response.mapItems
        }
    }
    
    private func formatAddress(_ placemark: CLPlacemark) -> String? {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
            placemark.country
        ].compactMap { $0 }
        
        return components.joined(separator: ", ")
    }
    
    private func selectLocation(_ item: MKMapItem) {
        let location = TodoItem.Location(
            latitude: item.placemark.coordinate.latitude,
            longitude: item.placemark.coordinate.longitude,
            name: item.name ?? "",
            address: formatAddress(item.placemark) ?? ""
        )
        selectedLocation = location
        dismiss()
    }
    
    private func selectCurrentLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let location = TodoItem.Location(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    name: "Current Location",
                    address: formatAddress(placemark) ?? ""
                )
                selectedLocation = location
                dismiss()
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var currentAddress: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            locationManager.stopUpdatingLocation()
            location = nil
            currentAddress = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        // Reverse geocode to get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let placemark = placemarks?.first {
                let components = [
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }
                
                self?.currentAddress = components.joined(separator: ", ")
            }
        }
    }
} 
