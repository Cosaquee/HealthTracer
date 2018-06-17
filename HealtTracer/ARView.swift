import Foundation

import UIKit
import SceneKit
import ARKit
import MetalKit
import MapKit

import RealmSwift
import GeoQueries
import PopupDialog

class ARView: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    let configuration = ARWorldTrackingConfiguration()
    
    var location = CLLocation()
    var locationManager = CLLocationManager();
    
    var userLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        
        //Add recognizer to sceneview
        sceneView.addGestureRecognizer(tap)
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
    }
    
    @IBAction func showTicTack(_ sender: UIButton) {
        let realm = try! Realm()
        
//        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude)
        let results = try! Realm()
            .findNearby(type: LocationMark.self, origin: CLLocationCoordinate2D(latitude: self.userLocation.coordinate.latitude, longitude: self.userLocation.coordinate.longitude), radius: 500, sortAscending: nil)

        for location in results {
            let node = SCNNode()
            
            let capsule = TreningNode(capRadius: 0.1, height: 0.3)
            capsule.location = location
            capsule.heartRate = location.meanHeartRate
            node.geometry = capsule
            
            let randomXPosition = arc4random_uniform(3)
            node.position = SCNVector3(Int(randomXPosition), 0, -1)
            
            node.geometry?.firstMaterial?.specular.contents = UIColor.red
            
            if (location.meanHeartRate < 75.0 ) {
                node.geometry?.firstMaterial?.diffuse.contents  = UIColor.green
            } else if (location.meanHeartRate >= 75.0 && location.meanHeartRate < 80.0) {
                node.geometry?.firstMaterial?.diffuse.contents  = UIColor.orange
            } else if (location.meanHeartRate >= 80 && location.meanHeartRate < 90) {
                node.geometry?.firstMaterial?.diffuse.contents  = UIColor.red
            } else {
                node.geometry?.firstMaterial?.diffuse.contents  = UIColor.black
            }
            
            self.sceneView.autoenablesDefaultLighting = true
            self.sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func deployTicTack(location: LocationMark) -> Void {
        let node = SCNNode()
        
        let capsule = TreningNode(capRadius: 0.1, height: 0.3)
        capsule.location = location
        capsule.heartRate = location.meanHeartRate
        node.geometry = capsule
        
        let randomXPosition = arc4random_uniform(3)
        node.position = SCNVector3(Int(randomXPosition), 0, -1)
        
        node.geometry?.firstMaterial?.specular.contents = UIColor.red
        
        if (location.meanHeartRate < 75.0 ) {
            node.geometry?.firstMaterial?.diffuse.contents  = UIColor.green
        } else if (location.meanHeartRate >= 75.0 && location.meanHeartRate < 80.0) {
            node.geometry?.firstMaterial?.diffuse.contents  = UIColor.orange
        } else if (location.meanHeartRate >= 80 && location.meanHeartRate < 90) {
            node.geometry?.firstMaterial?.diffuse.contents  = UIColor.red
        } else {
            node.geometry?.firstMaterial?.diffuse.contents  = UIColor.black
        }
        
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.scene.rootNode.addChildNode(node)
    }

    
    @IBAction func add(_ sender: Any) {
        let title = "Do you want to save current time and heartrate?"

        let treningTime = self.getCurrentTreningTime()

        self.getMeanHeartRate(result: { (trening, heartRate) in
            let popup = PopupDialog(title: title,
                                    message: "Current trening time: \(treningTime) \(String(heartRate))",
                buttonAlignment: .horizontal,
                transitionStyle: .zoomIn,
                gestureDismissal: true,
                hideStatusBar: true) {
                    let realm = try! Realm()
                    
                    let locationMark = LocationMark()
                    
                    locationMark.meanHeartRate = heartRate
                    
                    locationMark.lat = self.userLocation.coordinate.latitude
                    locationMark.lng = self.userLocation.coordinate.longitude
                    
                    locationMark.trening = trening

                    try! realm.write {
                        realm.add(locationMark)
                    }
                    
                    self.deployTicTack(location: locationMark)
            }
            
            
            let buttonOne = CancelButton(title: "Cancel") { [weak self] in
                print("canceled")
            }
            
            let buttonTwo = DefaultButton(title: "Save") { [weak popup] in
                
            }
            
            popup.addButtons([buttonOne, buttonTwo])
            
            self.present(popup, animated: true, completion: nil)
        })
    }
    
    func getMeanHeartRate(result: @escaping (Trening, Double) -> Void) {
        let realm = try! Realm()
        
        let trenings = realm.objects(Trening.self).filter("inProggres = true")
        
        guard let trening = trenings.first else {
            return result(Trening(), 0.0)
        }
        
        var meanHeartRate: Double = 0
        for trening in trening.locations {
            meanHeartRate += trening.heartRate
        }
        
        let heartRate = (meanHeartRate / Double(trening.locations.count))
            
        result(trening, heartRate)
    }
    
    func getCurrentTreningTime() -> String {
        
        let realm = try! Realm()
        
        let trenings = realm.objects(Trening.self).filter("inProggres = true")
        
        guard let trening = trenings.first else {
            return ""
        }
        
        let treningInterval = -trening.StartDate.timeIntervalSinceNow
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.allowedUnits = [.hour, .minute]
        
        let treningTime = formatter.string(from: treningInterval) ?? ""
        
        return "\(treningTime)"
    }
    
    func showTreningInfo(node: TreningNode) {
        let treningInterval = -node.location.trening.StartDate.timeIntervalSinceNow
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        formatter.allowedUnits = [.hour, .minute]
        
        let treningTime = formatter.string(from: treningInterval) ?? ""
        
        var mean = 0.0
        for trening in node.location.trening.locations {
            mean += trening.heartRate
        }
        
        mean = mean / Double(node.location.trening.locations.count) 
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH.mm"
        let startDate = dateFormatter.string(from: node.location.trening.StartDate)
        
        let alert = UIAlertController(title: "Trening info", message: "Trening from \(startDate) Trening took \(treningTime) minutes, mean heart rate was \(mean)", preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func handleTap(rec: UITapGestureRecognizer) {
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: self.sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            
            if !hits.isEmpty {
                let node = hits.first?.node
                
                self.showTreningInfo(node: node?.geometry as! TreningNode)
            }
        }
    }
}

extension ARView: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.last!
  
        self.userLocation = currentLocation
    }
}
