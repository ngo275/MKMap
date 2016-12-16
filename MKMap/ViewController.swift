//
//  ViewController.swift
//  MKMap
//
//  Created by ShuichiNagao on 2016/12/10.
//  Copyright © 2016 ShuichiNagao. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController {

    
    @IBOutlet weak var mapView: MKMapView!
    
    var userAnnotationImage: UIImage?
    var userAnnotation: UserAnnotation?
    var accuracyRangeCircle: MKCircle?
    var polyline: MKPolyline?
    var isZooming: Bool?
    var isBlockingAutoZoom: Bool?
    var zoomBlockingTimer: Timer?
    var didInitialZoom: Bool?
    
    var polys: MKPolyline?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //mapView.mapType = .satelliteFlyover
        //mapView.camera.pitch = 50

        //DataManager.shared.read()
        //DataManager.shared.delete()
        
        mapView.showsUserLocation = false
        
        userAnnotationImage = UIImage(named: "icon")!
        
        accuracyRangeCircle = MKCircle(center: CLLocationCoordinate2D.init(latitude: 41.887, longitude: -87.622), radius: 50)
        self.mapView.add(self.accuracyRangeCircle!)
        
        
        didInitialZoom = false
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateMap(_:)), name: Notification.Name(rawValue:"didUpdateLocation"), object: nil)
        //drawPolylineFromData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.showTurnOnLocationServiceAlert(_:)), name: Notification.Name(rawValue:"showTurnOnLocationServiceAlert"), object: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showTurnOnLocationServiceAlert(_ notification: NSNotification){
        let alert = UIAlertController(title: "Turn on Location Service", message: "To use location tracking feature of the app, please turn on the location service from the Settings app.", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        
        present(alert, animated: true, completion: nil)
        
    }
    
    func updateMap(_ notification: NSNotification){
        if let userInfo = notification.userInfo{
            
            updatePolylines()
            //mapView.camera.pitch = 50
            if let newLocation = userInfo["location"] as? CLLocation{
                zoomTo(location: newLocation)
            }
            
        }
    }
    
    func updatePolylines() {
        var coordinateArray = [CLLocationCoordinate2D]()
        
        for loc in LocationManager.shared.locationDataArray {
            coordinateArray.append(loc.coordinate)
        }
        print(LocationManager.shared.locationDataArray)
//        if LocationManager.shared.locationDataArray.count == 10 {
//            DataManager.shared.save()
//        }
        
        clearPolyline()
        
        polys = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count)
        
        let polyline = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count) as MKOverlay
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))

        mapView.addGestureRecognizer(tapGestureRecognizer)
        
        mapView.add(polyline)
        
    }
    
    func clearPolyline() {
        
        //LocationManager.shared.locationDataArray.forEach(saveData)
        if polyline != nil {
            mapView.remove(polyline!)
            
            polyline = nil
        }
    }
    
    func zoomTo(location: CLLocation) {
        if didInitialZoom == false {
            let coordinate = location.coordinate
            let region = MKCoordinateRegionMakeWithDistance(coordinate, 300, 300)
            mapView.setRegion(region, animated: false)
            didInitialZoom = true
        }
        
        if isBlockingAutoZoom == false {
            isZooming = true
            mapView.setCenter(location.coordinate, animated: true)
        }
        
        var accuracyRadius = 50.0
        if location.horizontalAccuracy > 0 {
            if location.horizontalAccuracy > accuracyRadius{
                accuracyRadius = location.horizontalAccuracy
            }
        }
        
        mapView.remove(accuracyRangeCircle!)
        accuracyRangeCircle = MKCircle(center: location.coordinate, radius: accuracyRadius as CLLocationDistance)
        mapView.add(accuracyRangeCircle!)
        
        if userAnnotation != nil {
            mapView.removeAnnotation(userAnnotation!)
        }
        
        userAnnotation = UserAnnotation(coordinate: location.coordinate, title: "", subtitle: "")
        mapView.addAnnotation(userAnnotation!)
    }
    
    func drawPolylineFromData() {
        let locsData = DataManager.shared.read()
        
        guard let locs = locsData else { return }
        
        var coordinateArray = [CLLocationCoordinate2D]()
        
        for loc in locs {
            let c = CLLocationCoordinate2D(latitude: loc.lat as! CLLocationDegrees, longitude: loc.lon as! CLLocationDegrees)
            coordinateArray.append(c)
        }
        print(LocationManager.shared.locationDataArray)
        //        if LocationManager.shared.locationDataArray.count == 10 {
        //            DataManager.shared.save()
        //        }
        
        //clearPolyline()
        
        let polyline = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        
        mapView.addGestureRecognizer(tapGestureRecognizer)
        
        mapView.add(polyline)
        
        //print(locs)
    }
    
    func tapGesture(_ tapGesture: UITapGestureRecognizer) {
        let tappedMapView = tapGesture.view
        let tappedPoint = tapGesture.location(in: tappedMapView)
        let tappedCoordinates = mapView.convert(tappedPoint, toCoordinateFrom: tappedMapView)
        let point: MKMapPoint = MKMapPointForCoordinate(tappedCoordinates)

        
        let touchLocation = tapGesture.location(in: mapView)
        let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
        print(locationCoordinate)
        
        guard let p = polys else { return }
        
        let closestPoint = distanceOfPoint(pt: point, poly: p)
        
        print(closestPoint ?? "近くのポイントなし")
        
    }
    
    func distanceOfPoint(pt: MKMapPoint, poly: MKPolyline) -> CLLocation? {
        let distance: Double = Double(MAXFLOAT)
        var linePoints: [MKMapPoint] = []
        //var polyPoints = UnsafeMutablePointer<MKMapPoint>.allocate(capacity: poly.pointCount)
        for point in UnsafeBufferPointer(start: poly.points(), count: poly.pointCount) {
            linePoints.append(point)
            print("point: \(point.x),\(point.y)")
        }
        
        if linePoints.count < 3 {
            return nil
        }
        
        for n in 0...linePoints.count - 2 {
            let ptA = linePoints[n]
            let ptB = linePoints[n+1]
            let xDelta = ptB.x - ptA.x
            let yDelta = ptB.y - ptA.y
            if (xDelta == 0.0 && yDelta == 0.0) {
                // Points must not be equal
                continue
            }
            let u: Double = ((pt.x - ptA.x) * xDelta + (pt.y - ptA.y) * yDelta) / (xDelta * xDelta + yDelta * yDelta)
            var ptClosest = MKMapPoint()
            if (u < 0.0) {
                ptClosest = ptA
            } else if (u > 1.0) {
                ptClosest = ptB
            } else {
                ptClosest = MKMapPointMake(ptA.x + u * xDelta, ptA.y + u * yDelta);
            }
            print("Tapped point is: \(MKCoordinateForMapPoint(ptClosest))")
            
            let minDistance: Double = 8
            
            if min(distance, MKMetersBetweenMapPoints(ptClosest, pt)) <= minDistance {
                let coordinate = MKCoordinateForMapPoint(ptClosest)
                
                return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        }
        
        return nil
    }

}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay === accuracyRangeCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
            circleRenderer.fillColor = UIColor(white: 0.0, alpha: 0.25)
            circleRenderer.lineWidth = 0
            
            return circleRenderer
        } else {
            let polylineRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
            polylineRenderer.strokeColor = UIColor(rgb: 0x1b60fe)
            polylineRenderer.alpha = 0.5
            polylineRenderer.lineWidth = 5.0
            
            return polylineRenderer
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            
            return nil
        } else {
            let identifier = "UserAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView != nil {
                annotationView!.annotation = annotation
            } else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            annotationView!.canShowCallout = false
            annotationView!.image = userAnnotationImage
            
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if isZooming == true {
            isZooming = false
            isBlockingAutoZoom = false
        } else {
            isBlockingAutoZoom = true
            if let timer = zoomBlockingTimer {
                if timer.isValid {
                    timer.invalidate()
                }
            }
            self.zoomBlockingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] (Timer) in
                self?.zoomBlockingTimer = nil
                self?.isBlockingAutoZoom = false
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // annotationをtapしたときよばれる
    }
}

