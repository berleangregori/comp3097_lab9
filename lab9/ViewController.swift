//
//  ViewController.swift
//  lab9
//
//  Created by Joshua Nuezca on 2025-03-20.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {

    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - Properties
    var coordinates: [CLLocationCoordinate2D] = []
    var annotations: [MKPointAnnotation] = []
    var lines: [MKPolyline] = []
    var triangleOverlay: MKPolygon?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(gesture)
    }

    // MARK: - Gesture Handler
    @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        if let indexToRemove = coordinates.firstIndex(where: { distanceBetween($0, touchCoordinate) < 100 }) {
            removePoint(at: indexToRemove)
            return
        }

        guard coordinates.count < 3 else { return }

        let annotation = MKPointAnnotation()
        annotation.coordinate = touchCoordinate
        mapView.addAnnotation(annotation)
        coordinates.append(touchCoordinate)
        annotations.append(annotation)

        if coordinates.count == 3 {
            drawTriangle()
        }
    }

    // MARK: - Triangle & Overlay Drawing
    func drawTriangle() {
        clearOverlays()

        for i in 0..<3 {
            let coord1 = coordinates[i]
            let coord2 = coordinates[(i + 1) % 3]
            let polyline = MKPolyline(coordinates: [coord1, coord2], count: 2)
            lines.append(polyline)
            mapView.addOverlay(polyline)

            let midPoint = CLLocationCoordinate2D(
                latitude: (coord1.latitude + coord2.latitude) / 2,
                longitude: (coord1.longitude + coord2.longitude) / 2
            )
            let distance = distanceBetween(coord1, coord2)
            let annotation = MKPointAnnotation()
            annotation.coordinate = midPoint
            annotation.title = String(format: "%.2f km", distance / 1000)
            mapView.addAnnotation(annotation)
        }

        triangleOverlay = MKPolygon(coordinates: coordinates, count: 3)
        mapView.addOverlay(triangleOverlay!)
    }

    func clearOverlays() {
        mapView.removeOverlays(mapView.overlays)
        lines.removeAll()
        triangleOverlay = nil
    }

    func removePoint(at index: Int) {
        mapView.removeAnnotation(annotations[index])
        annotations.remove(at: index)
        coordinates.remove(at: index)
        clearOverlays()
    }

    func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return loc1.distance(from: loc2)
    }

    // MARK: - Map Overlay Renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = .green
            renderer.lineWidth = 3
            return renderer
        }

        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(overlay: polygon)
            renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 1
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: - Button Action
    @IBAction func routeGuidanceTapped(_ sender: UIButton) {
        guard coordinates.count == 3 else { return }

        for i in 0..<3 {
            let source = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[i]))
            let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates[(i + 1) % 3]))

            let request = MKDirections.Request()
            request.source = source
            request.destination = destination
            request.transportType = .automobile

            let directions = MKDirections(request: request)
            directions.calculate { response, error in
                guard let route = response?.routes.first else { return }
                self.mapView.addOverlay(route.polyline)
            }
        }
    }
}

