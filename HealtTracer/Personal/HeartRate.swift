//
//  HeartRate.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 14/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import UIKit
import HealthKit

class HeartRate: UIViewController {
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var heartImage: UIImageView!
    
    let healthStore = HKHealthStore()
    var timer = Timer()
    
    func fetchHeartRate(result: @escaping (Double) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
                if HKHealthStore.isHealthDataAvailable() {
                    self.healthStore.requestAuthorization(toShare: nil, read:[heartRateType], completion:{(success, error) in
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateFormat = "hh:mm:ss"
        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MM/dd/YYYY"
        
                        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        
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
                                    self.heartRateLabel.text = "0"
                                    return
                                }
        
                                let heartRateUnit = HKUnit(from: "count/min")
                                let heartRate = hrLatest
                                    .quantity
                                    .doubleValue(for: heartRateUnit)
                                print("Heart Rate: ", heartRate)
                                result(heartRate)
                        }
        
                        self.healthStore.execute(query)
                    })
                }
    }
    
    @objc func update() {
        self.fetchHeartRate(result: {heartRate in
            DispatchQueue.main.async {
                print(heartRate)
                self.heartRateLabel.text = "\(Int(heartRate))"
            }
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIView.animate(withDuration: 1, animations: {
            self.heartImage.frame.size.width += 5
            self.heartImage.frame.size.height += 5
        }) { _ in
            UIView.animate(withDuration: 1, delay: 0.25, options: [.autoreverse, .repeat], animations: {
                self.heartImage.frame.size.width -= 5
                self.heartImage.frame.size.height -= 5
            })
        }
        
        Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)

    }
}
