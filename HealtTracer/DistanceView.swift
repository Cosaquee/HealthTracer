//
//  DistanceView.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 15/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class DistanceView: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var distanceMadeLabel: UILabel!
    @IBOutlet weak var distanceGoalLabel: UILabel!
    @IBOutlet weak var distanceTextField: UITextField!
    @IBOutlet weak var statusImage: UIImageView!
    
//    @IBAction func editGoal(_ sender: Any) {
//        let realm = try! Realm()
//
//        try! realm.write {
//            let distanceGoal = DistanceGoal()
//            distanceGoal.goal = Int(distanceTextField.text!)!
//        }
//
//        distanceTextField.returnKeyType = .done
//    }
    
    @IBAction func editGoal(_ sender: Any) {
        print("Edit")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(DistanceGoal.self))
            let distanceGoal = DistanceGoal()
            distanceGoal.goal = Int(distanceTextField.text!)!
            realm.add(distanceGoal)
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let realm = try! Realm()
        self.distanceTextField.delegate = self
        
        let distances = realm.objects(DistanceGoal.self)
        
        guard let distanceGoal = distances.first else {
            self.distanceTextField.text = "4km"
            return
        }
        
        let hkm = HealtKitManager()
        hkm.readDistance(result: { (weight, _) in
            DispatchQueue.main.async {
                self.distanceMadeLabel.text = "\(Int(weight))km"
                self.distanceTextField.text = "\(distanceGoal.goal)"
                
                if (weight < Double(distanceGoal.goal)) {
                    print("Weight less than goal")
                    self.statusImage.image = UIImage(named: "sad")
                } else {
                    print("Goal bigger than goal")
                    self.statusImage.image = UIImage(named: "smile")
                }
            }
        })
    }
}
