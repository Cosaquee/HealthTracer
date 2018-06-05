//
//  ARView.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 16/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation

import UIKit
import SceneKit
import ARKit
import MetalKit

import RealmSwift

import PopupDialog

class ARView: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    @IBAction func add(_ sender: Any) {
        let title = "Do you want to save current time and heartrate?"

        let treningTime = self.getCurrentTreningTime()
        let meanHeartRate = self.getMeanHeartRate()
        
        let popup = PopupDialog(title: title,
                                message: "Current trening time: \(treningTime) \(String(meanHeartRate))",
                                buttonAlignment: .horizontal,
                                transitionStyle: .zoomIn,
                                gestureDismissal: true,
                                hideStatusBar: true) {
                                    print("Completed")
        }
        
        let buttonOne = CancelButton(title: "Cancel") { [weak self] in
            print("canceled")
        }
        
        let buttonTwo = DefaultButton(title: "Save") { [weak popup] in
            let node = SCNNode()
            node.geometry = SCNCapsule(capRadius: 0.1, height: 0.3)
            node.position = SCNVector3(0, 0, -1)
            //        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.03)
            node.geometry?.firstMaterial?.specular.contents = UIColor.red
            print(meanHeartRate)
            if (meanHeartRate < 60.0 ) {
                print("mean hertRate less than 60")
                node.geometry?.firstMaterial?.specular.contents = UIColor.white
            } else if (meanHeartRate >= 60.0 && meanHeartRate < 70.0) {
                print("mean hertRate less than 70")
                node.geometry?.firstMaterial?.specular.contents = UIColor.gray
            } else if (meanHeartRate >= 70 && meanHeartRate < 80) {
                node.geometry?.firstMaterial?.specular.contents = UIColor.orange
                print("mean hertRate less than 80")
            } else {
                node.geometry?.firstMaterial?.specular.contents = UIColor.red
            }

//            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue

            
            self.sceneView.autoenablesDefaultLighting = true
            self.sceneView.scene.rootNode.addChildNode(node)
        }
        
        popup.addButtons([buttonOne, buttonTwo])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func getMeanHeartRate() -> Double {
        let realm = try! Realm()
        
        let trenings = realm.objects(Trening.self).filter("inProggres = true")
        
        guard let trening = trenings.first else {
            return 0.0
        }
        
        let trenignStartDate = trening.StartDate
        
        let heartRates = realm.objects(UserLocation.self).filter("locationDate > %@ and locationDate < %@", trenignStartDate, Date())
        
        return (heartRates.sum(ofProperty: "heartRate") / Double(heartRates.count))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.session.run(configuration)
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
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
}

extension UIViewController {
    class func displaySpinner(onView : UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}
