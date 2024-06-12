import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {
    @State private var markerCount = 0

    func makeCoordinator() -> Coordinator {
        Coordinator(self, markerCount: $markerCount)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let style = "radar-default-v1"
        let publishableKey = "<RADAR_PUBLISHABLE_KEY>"
        let styleURL = URL(string: "https://api.radar.io/maps/styles/\(style)?publishableKey=\(publishableKey)")

        // create new map view
        // https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnmapview
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.logoView.isHidden = true
        mapView.isRotateEnabled = false

        mapView.setCenter(CLLocationCoordinate2D(latitude: 40.7342, longitude: -73.9911), zoomLevel: 11, animated: false)

        // set min and max zoom levels
        mapView.maximumZoomLevel = 15
        mapView.minimumZoomLevel = 7
        mapView.allowsTilting = false
        
        // setup map tap listener
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        
        // add Radar logo
        let logoImageView = UIImageView(image: UIImage(named: "radar-logo"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(logoImageView)
        NSLayoutConstraint.activate([
          logoImageView.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -10),
          logoImageView.leadingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.leadingAnchor, constant: 10),
          logoImageView.widthAnchor.constraint(equalToConstant: 74),
          logoImageView.heightAnchor.constraint(equalToConstant: 26)
        ])
        
        // setup map delegate
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
        // Update the map view if needed
    }
    
    // delegate for map interactions
    // https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnmapviewdelegate
    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: MapView
        @Binding var markerCount: Int
        var isMapLoaded = false
        
        init(_ parent: MapView, markerCount: Binding<Int>) {
            self.parent = parent
            self._markerCount = markerCount
        }
        
        // handle map and style loaded
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            self.isMapLoaded = true
        }
        func mapViewDidFinishLoadingMap(_ mapView: MLNMapView) {
            self.isMapLoaded = true
        }
        
        // handle annotation
        func mapView(_ mapView: MLNMapView, imageFor annotation: MLNAnnotation) -> MLNAnnotationImage? {
            // provide the custom image for the annotation
            let markerId = "marker"
            if let annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: markerId) {
                return annotationImage
            } else {
                guard let image = UIImage(named: markerId) else {
                    return nil
                }
                let annotationImage = MLNAnnotationImage(image: image, reuseIdentifier: markerId)
                return annotationImage
            }
        }
        
        // show popup
        func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
            return true
        }
        
        // handle marker tap
        func mapView(_ mapView: MLNMapView, didSelect marker: MLNAnnotation) {
            print("Marker tapped: \(String(describing: marker.title ?? ""))")
        }

        // handle map tap - create new marker at tap location
        @objc func handleMapTap(sender: UITapGestureRecognizer) {
            guard let mapView = sender.view as? MLNMapView else { return }

            // convert tap location to geographic coordinate
            let tapPoint: CGPoint = sender.location(in: mapView)
            let tapCoordinate: CLLocationCoordinate2D = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            print("Map tapped at coordinate: \(tapCoordinate.latitude), \(tapCoordinate.longitude)")
            
            if isMapLoaded {
                // increment marker count
                markerCount += 1
                
                // create a new marker with popup text
                // https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlnpointannotation
                let point = MLNPointAnnotation()
                point.coordinate = tapCoordinate
                point.title = "Marker \(markerCount)"
                point.subtitle = "This is marker number \(markerCount)"
                mapView.addAnnotation(point)
                
                // refit the map to keep all markers in view
                refitMapToMarkers(mapView)
            } else {
                print("Map is not loaded yet")
            }
        }
        
        // refit the map to
        func refitMapToMarkers(_ mapView: MLNMapView) {
            guard let annotations = mapView.annotations, !annotations.isEmpty else { return }
            
            // https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre/mlncoordinatebounds
            var bounds = MLNCoordinateBounds()
            bounds.sw = annotations.first!.coordinate
            bounds.ne = annotations.first!.coordinate
            
            for annotation in annotations {
                bounds.sw.latitude = min(bounds.sw.latitude, annotation.coordinate.latitude)
                bounds.sw.longitude = min(bounds.sw.longitude, annotation.coordinate.longitude)
                bounds.ne.latitude = max(bounds.ne.latitude, annotation.coordinate.latitude)
                bounds.ne.longitude = max(bounds.ne.longitude, annotation.coordinate.longitude)
            }
            
            let insets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
            let camera = mapView.cameraThatFitsCoordinateBounds(bounds, edgePadding: insets)
            mapView.setCamera(camera, animated: true)
        }
    }
}

#Preview {
    MapView()
}
