import SwiftUI
import MapKit

struct LocationMapView: View {
    let location: TodoItem.Location
    let allowsInteraction: Bool
    @Binding var position: MapCameraPosition
    
    init(location: TodoItem.Location, allowsInteraction: Bool, position: Binding<MapCameraPosition>) {
        self.location = location
        self.allowsInteraction = allowsInteraction
        self._position = position
    }
    
    var body: some View {
        Map(position: $position) {
            Marker(location.name, coordinate: coordinate)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .mapStyle(.standard)
        .mapControlVisibility(.hidden)
        .gesture(allowsInteraction ? nil : DragGesture())
        .simultaneousGesture(allowsInteraction ? nil : TapGesture().onEnded { _ in })
        .allowsHitTesting(allowsInteraction)
        .interactiveDismissDisabled(!allowsInteraction)
        .onAppear {
            position = .camera(MapCamera(
                centerCoordinate: coordinate,
                distance: 1000
            ))
        }
    }
    
    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
    
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

struct LocationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let location: TodoItem.Location
    @State private var position: MapCameraPosition
    
    init(location: TodoItem.Location) {
        self.location = location
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        self._position = State(initialValue: .camera(MapCamera(
            centerCoordinate: coordinate,
            distance: 1000
        )))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LocationMapView(location: location, allowsInteraction: true, position: $position)
                    .ignoresSafeArea()
                
                // Content overlay
                VStack(spacing: 0) {
                    // Location info at top
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(location.address)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    
                    // Recenter button
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                let coordinate = CLLocationCoordinate2D(
                                    latitude: location.latitude,
                                    longitude: location.longitude
                                )
                                position = .camera(MapCamera(
                                    centerCoordinate: coordinate,
                                    distance: 1000
                                ))
                            }
                            FeedbackManager.shared.playHaptic(style: .light)
                        } label: {
                            Image(systemName: "location")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding(.trailing, 8)
                    }
                    .padding(.vertical, 8)
                    
                    Spacer()
                    
                    VStack {
                        Button {
                            openInMaps()
                        } label: {
                            HStack {
                                Text("Open in Maps")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.name
        mapItem.openInMaps()
    }
} 
