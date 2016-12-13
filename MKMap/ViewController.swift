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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DataManager.shared.read()
        //DataManager.shared.delete()
        
        mapView.showsUserLocation = false
        
        userAnnotationImage = UIImage(named: "icon")!
        
        accuracyRangeCircle = MKCircle(center: CLLocationCoordinate2D.init(latitude: 41.887, longitude: -87.622), radius: 50)
        self.mapView.add(self.accuracyRangeCircle!)
        
        
        didInitialZoom = false
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateMap(_:)), name: Notification.Name(rawValue:"didUpdateLocation"), object: nil)
        
        
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
        
//        if LocationManager.shared.locationDataArray.count == 10 {
//            DataManager.shared.save()
//        }
        
        clearPolyline()
        
        let polyline = MKPolyline(coordinates: coordinateArray, count: coordinateArray.count) as MKOverlay
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
        
        //print(locs)
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
}

