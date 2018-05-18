//
//  FloorView.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 15/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit

class FloorView: UIViewController {
    
    @IBOutlet weak var climbedFloorsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let hkm = HealtKitManager()
        hkm.readFloors(result: { weight in
            DispatchQueue.main.async {
                self.climbedFloorsLabel.text = "\(Int(weight))"
            }
        })
    }
}
