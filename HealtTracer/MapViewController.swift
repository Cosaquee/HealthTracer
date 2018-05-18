//
//  MapViewController.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 17/04/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RealmSwift
import HealthKit
import GeoQueries

class MapViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager();
    private var currentLocation: CLLocation?
    
    var tracing: Bool = false
    
    @IBOutlet weak var tracingButton: UIButton!
    
    @IBAction func tracingButton(_ sender: Any) {
        let trening = Trening()
        trening.inProggres = true
        
        DBManager.sharedInstance.startTraining(trening: trening)
        
        if(self.tracing == true) {
            tracingButton.setTitle("Start tracing", for: .normal)
            let realm = try! Realm()
            
            let trenings = realm.objects(Trening.self).filter("inProggres = true")
            
            guard let trening = trenings.first else {
                return
            }
            try! realm.write {
                trening.inProggres  = false
            }

            
            self.tracing = false
        } else {
            tracingButton.setTitle("Stop tracing", for: .normal)
            self.tracing = true
        }
        
        if self.tracing {
            if (CLLocationManager.locationServicesEnabled()) {
                locationManager = CLLocationManager()
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestAlwaysAuthorization()
                locationManager.startUpdatingLocation()
            }

        } else {
            locationManager.stopUpdatingLocation()
        }

    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    func getCurrentHeartRate() -> Double {
        let hkm = HealtKitManager()
        var temp = 0.0
        hkm.getHeartRate(completion: { heartRate in
            temp = heartRate
        })
        
        return temp
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location = locations.last! as CLLocation
        
        let userLocation = UserLocation()
        
        let savedLocations = DBManager.sharedInstance.findNearby(lat: location.coordinate.latitude, lon: location.coordinate.longitude, radius: 1.0)
        
        if(savedLocations.count == 0) {
            
            if self.tracing {
                userLocation.lat = location.coordinate.latitude
                userLocation.lng = location.coordinate.longitude
                
                let hkm = HealtKitManager()
                
                hkm.getHeartRate(completion: { heartRate in
                    let realm = try! Realm()
                    try! realm.write {
                        userLocation.heartRate = heartRate
                        realm.add(userLocation)
                    }
                })
            }
        }
        
        savedLocations.forEach { loc in
            if(!checkToday(locationDate: loc.locationDate)) {
                if self.tracing {
                    userLocation.lat = location.coordinate.latitude
                    userLocation.lng = location.coordinate.longitude
                    let hkm = HealtKitManager()

                    hkm.getHeartRate(completion: { heartRate in
                        let realm = try! Realm()
                        try! realm.write {
                            userLocation.heartRate = heartRate
                            print("Saved user location", userLocation)
                            realm.add(userLocation)
                        }
                    })
                }
            }
        }


        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        let realm = try! Realm()
        let locations = try! realm.findNearby(type: UserLocation.self,
                                              origin: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                                              radius: 500,
                                              sortAscending: nil)
        
//        let locations = DBManager.sharedInstance.getPointsInRegion(region: region)
        
        for uLocation in locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: uLocation.lat, longitude: uLocation.lng)
            annotation.subtitle = "\(String(uLocation.heartRate))"
            self.mapView.addAnnotation(annotation)
        }
        
        self.mapView.showsUserLocation = true
        self.mapView.setRegion(region, animated: false)
        self.mapView.isScrollEnabled = true
    }
    
    func checkToday(locationDate: Date) -> Bool {
        let calendar = NSCalendar.current
        return calendar.isDateInToday(locationDate)
    }
}
