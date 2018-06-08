//
//  StepsVIew.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 15/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class StepsView: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var stepsMadeLabel: UILabel!
    @IBOutlet weak var stepGoalLabel: UILabel!
    @IBOutlet weak var stepsTextField: UITextField!
    @IBOutlet weak var statusImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        self.stepsTextField.delegate = self
        
        let steps = realm.objects(StepsGoal.self)
        
        var goal = 7000
        
        if let stepGoal = steps.first {
            goal = stepGoal.goal
        }
        
        let hkm = HealtKitManager()
        hkm.readSteps(result: { (weight, _) in
            DispatchQueue.main.async {
                self.stepsMadeLabel.text = "\(Int(weight))"
                self.stepsTextField.text = "\(goal)"
                
                if (weight < Double(goal)) {
                    self.statusImage.image = UIImage(named: "sad")
                } else {
                    self.statusImage.image = UIImage(named: "smile")
                }
            }
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(StepsGoal.self))
            let stepsGoal = StepsGoal()
            stepsGoal.goal = Int(stepsTextField.text!)!
            realm.add(stepsGoal)
        }
        return true
    }
}
