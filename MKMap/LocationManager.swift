//
//  LocationManager.swift
//  MKMap
//
//  Created by ShuichiNagao on 2016/12/10.
//  Copyright © 2016 ShuichiNagao. All rights reserved.
//

import Foundation
import CoreLocation

class LocationManager: NSObject {
    
    static var shared = LocationManager()
    
    let locationManager: CLLocationManager
    var locationDataArray: [CLLocation]
    var useFilter: Bool
    
    override init() {
    
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 7
        
        //locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationDataArray = [CLLocation]()
        
        useFilter = true
        
        super.init()
        
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager,
                                didFailWithError error: Error){
        if (error as NSError).domain == kCLErrorDomain && (error as NSError).code == CLError.Code.denied.rawValue{
            //User denied your app access to location information.
            showTurnOnLocationServiceAlert()
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                                didChangeAuthorization status: CLAuthorizationStatus){
        if status == .authorizedWhenInUse{
            //You can resume logging by calling startUpdatingLocation here
        }
    }
    
    func startUpdatingLocation(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.startUpdatingLocation()
        } else {
            //tell view controllers to show an alert
            showTurnOnLocationServiceAlert()
        }
    }
    
    func filterAndAddLocation(_ location: CLLocation) -> Bool{
        let age = -location.timestamp.timeIntervalSinceNow
        
        if age > 10{
            print("Locaiton is old.")
            return false
        }
        
        if location.horizontalAccuracy < 0{
            print("Latitidue and longitude values are invalid.")
            return false
        }
        
        if location.horizontalAccuracy > 100{
            print("Accuracy is too low.")
            return false
        }
        
        print("Location quality is good enough.")
        locationDataArray.append(location)
        
        return true
    }
    
    func showTurnOnLocationServiceAlert(){
        NotificationCenter.default.post(name: Notification.Name(rawValue:"showTurnOnLocationServiceAlert"), object: nil)
    }
    
    func notifiyDidUpdateLocation(newLocation:CLLocation){
        NotificationCenter.default.post(name: Notification.Name(rawValue:"didUpdateLocation"), object: nil, userInfo: ["location" : newLocation])
    }
}

//MARK: CLLocationManagerDelegate protocol methods
extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager,
                                didUpdateLocations locations: [CLLocation]){
        
        if let newLocation = locations.last{
            print("(\(newLocation.coordinate.latitude), \(newLocation.coordinate.latitude))")
            
            var locationAdded: Bool
            if useFilter{
                locationAdded = filterAndAddLocation(newLocation)
            }else{
                locationDataArray.append(newLocation)
                locationAdded = true
            }
            
            
            if locationAdded{
                notifiyDidUpdateLocation(newLocation: newLocation)
            }
            
        }
    }
}
