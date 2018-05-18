//
//  ActiveHoursView.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 15/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit

class ActiveHoursView: UIViewController {
    @IBOutlet weak var activeHoursLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let hkm = HealtKitManager()
        hkm.readActiveHours(result: { activeHours in
            DispatchQueue.main.async {
                self.activeHoursLabel.text = "\(Int(activeHours))"
            }
        })
    }
}
