//
//  CaloriesView.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 15/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit
class CaloriesView: UIViewController {
    
    @IBOutlet weak var currentCaloriesLabel: UILabel!
    @IBOutlet weak var goalCaloriesLabel: UILabel!
    @IBOutlet weak var statusFace: UIImageView!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hkm = HealtKitManager()
        hkm.readActiveEnergy(result: { (weight, goal) in
            DispatchQueue.main.async {
                self.currentCaloriesLabel.text = "\(Int(weight))"
                self.goalCaloriesLabel.text = "\(Int(goal))"
                
                if (weight < goal) {
                    print("Weight less than goal")
                    self.statusFace.image = UIImage(named: "sad")
                } else {
                    print("Goal bigger than goal")
                    self.statusFace.image = UIImage(named: "smile")
                }
            }
        })
    }
}
