//
//  HeightView.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 15/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit

class HeightView: UIViewController {
    @IBOutlet weak var weightLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hkm = HealtKitManager()

        hkm.readWeight(result: { weight in
            DispatchQueue.main.async {
                self.weightLabel.text = "\(Int(weight))kg"
            }
        })
    }
}
