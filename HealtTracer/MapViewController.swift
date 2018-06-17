import UIKit
import MapKit
import CoreLocation
import HealthKit

import RealmSwift
import GeoQueries

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tracingButton: UIButton!
    @IBOutlet weak var treningPicker: UIPickerView!
    
    let healthStore = HKHealthStore()
    
    var locationManager = CLLocationManager();
    private var currentLocation: CLLocation?

    var tracing: Bool = false
    
    var lastLocation: UserLocation = UserLocation()
    
    var trenings: [Trening] = []
    
    var selectedTrening: Trening = Trening()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        
        self.treningPicker.delegate = self
        self.treningPicker.dataSource = self
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        self.getTrenings(result: { trenings in
            self.trenings = Array(trenings)
        })
    }
    
    @IBAction func tracingButton(_ sender: Any) {
        if (self.tracing == false) {
            self.tracing = true
            tracingButton.setTitle("Stop tracing", for: .normal)
            
            let trening = Trening()
            trening.inProggres = true
            DBManager.sharedInstance.startTraining(trening: trening)
            
            
            self.treningPicker.delegate = self
            self.treningPicker.dataSource = self
            
            self.trenings.append(trening)
            self.treningPicker.reloadAllComponents()
            
            if (CLLocationManager.locationServicesEnabled()) {
                locationManager = CLLocationManager()
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.requestAlwaysAuthorization()
                locationManager.startUpdatingLocation()
            }
        } else {
            self.tracing = false;
            
            let realm = try! Realm()
            let trenings = realm.objects(Trening.self).filter("inProggres = true")

            guard let trening = trenings.first else {
                return
            }
            
            try! realm.write {
                trening.inProggres  = false
                trening.EndDate = Date()
            }
            tracingButton.setTitle("Start tracing", for: .normal)
            locationManager.stopUpdatingLocation()
        }
    }

    func getCurrentTrening(result: @escaping (Trening) -> Void) {
        let realm = try! Realm()
        let trenings = realm.objects(Trening.self).filter("inProggres = true")
        guard let trening = trenings.first else {
            return
        }
        result(trening)
    }
    
    
    func getTrenings(result: @escaping (Results<Trening>) -> Void) {
        let realm = try! Realm()
        result(realm.objects(Trening.self))
    }
    

    func checkNotSaved(locations: List<UserLocation>, latitude: Double, lng: Double) -> Bool {
        for location in locations {
            if (location.lng != lng && location.lat != latitude) {
                return true
            }
        }
        
        return false
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } else if  (annotation is MKPointAnnotation) {
            return nil
        } else {
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView") ?? MKAnnotationView()
            annotationView.image = UIImage(named: "heartRate")
            return annotationView
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let route: MKPolyline = overlay as! MKPolyline
            let routeRenderer = MKPolylineRenderer(polyline: route)
            routeRenderer.lineWidth = 3.0
            
            switch overlay.title {
            case "low":
                routeRenderer.strokeColor = UIColor.green
            case "mid":
                routeRenderer.strokeColor = UIColor.orange
            case "high":
                routeRenderer.strokeColor = UIColor.red
            case "ultra":
                routeRenderer.strokeColor = UIColor.black
            case "err":
                routeRenderer.strokeColor = UIColor.purple
            default:
                routeRenderer.strokeColor = UIColor.yellow
            }

            return routeRenderer
        }
        return MKOverlayRenderer()
    }
    
    func checkToday(locationDate: Date) -> Bool {
        let calendar = NSCalendar.current
        return calendar.isDateInToday(locationDate)
    }
    
    func fetchHeartRate(result: @escaping (Double) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore.requestAuthorization(toShare: nil, read:[heartRateType], completion:{(success, error) in
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "hh:mm:ss"
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/YYYY"
                
                let earlyDate = Calendar.current.date(
                    byAdding: .hour,
                    value: -1,
                    to: Date())
                
                let predicate = HKQuery.predicateForSamples(withStart: earlyDate, end: Date(), options: .strictEndDate)
                
                let sortDescriptor = NSSortDescriptor(
                    key: HKSampleSortIdentifierStartDate,
                    ascending: false)
                
                guard let sampleType = HKObjectType
                    .quantityType(forIdentifier: .heartRate) else {
                        return
                }
                let query = HKSampleQuery(
                    sampleType: sampleType,
                    predicate: predicate,
                    limit: Int(HKObjectQueryNoLimit),
                    sortDescriptors: [sortDescriptor]) { (_, results, error) in
                        
                        guard error == nil else {
                            print("Error: \(error!.localizedDescription)")
                            return
                        }
                        
                        guard let hrLatest = results?.first as? HKQuantitySample else {
                            return
                        }
                        
                        let heartRateUnit = HKUnit(from: "count/min")
                        let heartRate = hrLatest
                            .quantity
                            .doubleValue(for: heartRateUnit)
                        result(heartRate)
                }
                
                self.healthStore.execute(query)
            })
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let currentLocation = locations.last! as CLLocation
        var userLocation = UserLocation()
        
        self.getCurrentTrening(result: { trening in
            
            let realm = try! Realm()
            
            let center = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            self.mapView.showsUserLocation = true
            self.mapView.setRegion(region, animated: false)
            self.mapView.isScrollEnabled = true
            
            var location = CLLocation()
            
            if (trening.locations.isEmpty) {
                location = currentLocation
            } else {
                location = CLLocation(latitude: trening.locations.last!.lat, longitude: trening.locations.last!.lng)
            }
            
//            var lastLocation = CLLocation(latitude: self.lastLocation.lat, longitude: self.lastLocation.lng)
            
//            let lastLocationCoordiate = CLLocation(latitude: trening.locations.last!.lat, longitude: trening.locations.last!.lng)
            let distance = location.distance(from: currentLocation)
            print(distance)
            if (distance > 10 || trening.locations.isEmpty) {
            
                userLocation.lat = currentLocation.coordinate.latitude
                userLocation.lng = currentLocation.coordinate.longitude
                
                self.fetchHeartRate(result: { heartRate in
                    DispatchQueue.main.async {
                        print("Draw line")
                        
                        var lastHeartRate = 0.0
                        if !(trening.locations.isEmpty) {
                            lastHeartRate = trening.locations.last!.heartRate
                        }
                        
                        let mean = (heartRate + lastHeartRate) / 2
                        
                        var locations: [CLLocationCoordinate2D] = [
                            CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                            CLLocationCoordinate2D(latitude: userLocation.lat, longitude: userLocation.lng)
                        ]
                        
                        if mean < 75 {
                            let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                            polyline.title = "low"
                            self.mapView.add(polyline)
                        } else if (mean > 75 && mean < 80 ) {
                            let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                            polyline.title = "mid"
                            self.mapView.add(polyline)
                        } else if (mean > 80 && mean < 90) {
                            let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                            polyline.title = "high"
                            self.mapView.add(polyline)
                        } else if (mean > 90 && mean < 100){
                            let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                            polyline.title = "ultra"
                            self.mapView.add(polyline)
                        } else {
                            let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                            polyline.title = "err"
                            self.mapView.add(polyline)
                        }
                        
                        let annotation = MKPointAnnotation()
                        
                        annotation.coordinate = CLLocationCoordinate2D(latitude: userLocation.lat, longitude: userLocation.lng)
                        annotation.title = "\(String(heartRate))"
                        
                        self.mapView.addAnnotation(annotation)
                        
                        let lU = UserLocation()
                        lU.lat = userLocation.lat
                        lU.lng = userLocation.lng
                        self.lastLocation = lU
                        
                        try! realm.write {
                            
                            userLocation.heartRate = heartRate
                            
                            userLocation.trening = trening
                            trening.locations.append(userLocation)
                            
                            self.lastLocation = userLocation
                            
                            realm.add(trening)
                        }
                        
                        location = CLLocation(latitude: trening.locations.last!.lat, longitude: trening.locations.last!.lng)
                    }
                })
            }
        })
        
//        self.getTrenings(result: { trenings in
            self.trenings = Array(trenings)
            var overlays: [MKCircle] = []

            let trening = self.selectedTrening
        
            var lastLocation = trening.locations.first
        
            for location in trening.locations {

                var locations: [CLLocationCoordinate2D] = [CLLocationCoordinate2D(latitude: lastLocation!.lat, longitude: lastLocation!.lng), CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)]
                
                let annotation = MKPointAnnotation()
                
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                annotation.title = "\(String(location.heartRate))"
                
                self.mapView.addAnnotation(annotation)

                overlays.append(MKCircle(center: CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng), radius: 100))

                let mean = ( lastLocation!.heartRate + location.heartRate) / 2
                print("Drawing choosen trening locations ", mean)
                if mean < 75 {
                    let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                    polyline.title = "low"
                    self.mapView.add(polyline)
                } else if (mean > 75 && mean < 80 ) {
                    let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                    polyline.title = "mid"
                    self.mapView.add(polyline)
                } else if (mean > 80 && mean < 90) {
                    let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                    polyline.title = "high"
                    self.mapView.add(polyline)
                } else if (mean > 90 && mean < 100){
                    let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                    polyline.title = "ultra"
                    self.mapView.add(polyline)
                } else {
                    let polyline = MKPolyline(coordinates: &locations, count: locations.count)
                    polyline.title = "err"
                    self.mapView.add(polyline)
                }
                lastLocation = location
            }
            self.mapView.addOverlays(overlays)
//        })
        
        let heartRateLocations = self.getHeartRateLocations()
        
        for heartRateLocation in heartRateLocations {
            let annotation = HeartRateAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: heartRateLocation.lat, longitude: heartRateLocation.lng)
//            annotation.
//            annotation.subtitle = "\(String(location.heartRate))"
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func getHeartRateLocations() -> [LocationMark] {
        let results = try! Realm()
            .findNearby(type: LocationMark.self, origin: self.mapView.centerCoordinate, radius: 500, sortAscending: nil)
        
        return Array(results)
    }
}

extension MapViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.trenings.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH.mm"
        return dateFormatter.string(from: trenings[row].StartDate)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let overlays = self.mapView.overlays
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        self.mapView.removeOverlays(overlays)
        print("Selected trening: ", self.trenings[row].locations.count)
        self.selectedTrening = self.trenings[row]
    }
}
