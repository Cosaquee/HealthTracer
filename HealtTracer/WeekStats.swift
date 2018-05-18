//
//  WeekStats.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 18/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit

class WeekStats: UIViewController {
    @IBOutlet weak var stepsCountLabel: UILabel!
    @IBOutlet weak var distanceCountLabel: UILabel!
    @IBOutlet weak var caloriesCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let hkm = HealtKitManager()
        hkm.getStepsCountIn7Days(result: { weight in
            DispatchQueue.main.async {
                self.stepsCountLabel.text = "\(Int(weight))"
            }
        })
        
        hkm.getDistanceIn7Days(result: { distance in
            DispatchQueue.main.async {
                self.distanceCountLabel.text = "\(Int(distance))km"
            }
        })
        
        hkm.getCaloriesIn7days(result: { calories in
            DispatchQueue.main.async {
                self.caloriesCountLabel.text = "\(Int(calories))"
            }
        })
    }
}
