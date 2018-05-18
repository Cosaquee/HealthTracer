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
//                        let hrLatest = results?[0] as! HKQuantitySample
                        
                        guard let hrLatest = results?.first as? HKQuantitySample else {
                            self.heartRateLabel.text = "0"
                            return
                        }
                        
                        let heartRateUnit = HKUnit(from: "count/min")
                        let heartRate = hrLatest
                            .quantity
                            .doubleValue(for: heartRateUnit)
                        
                        DispatchQueue.main.async {
                            self.heartRateLabel.text = "\(Int(heartRate))"
                        }
                }
                
                self.healthStore.execute(query)
            })
        }
    }
    
//    public func subscribeToHeartBeatChanges() {
//
//        // Creating the sample for the heart rate
//        guard let sampleType: HKSampleType =
//            HKObjectType.quantityType(forIdentifier: .heartRate) else {
//                return
//        }
//
//        /// Creating an observer, so updates are received whenever HealthKit’s
//        // heart rate data changes.
//        let _ = HKObserverQuery.init(
//            sampleType: sampleType,
//            predicate: nil) { [weak self] _, _, error in
//                guard error == nil else {
//                    return
//                }
//
//                /// When the completion is called, an other query is executed
//                /// to fetch the latest heart rate
//                self?.fetchLatestHeartRateSample(completion: { sample in
//                    guard let sample = sample else {
//                        return
//                    }
//
//                    /// The completion in called on a background thread, but we
//                    /// need to update the UI on the main.
//                    DispatchQueue.main.async {
//
//                        /// Converting the heart rate to bpm
//                        let heartRateUnit = HKUnit(from: "count/min")
//                        let heartRate = sample
//                            .quantity
//                            .doubleValue(for: heartRateUnit)
//
//                        print(heartRate)
//
//                        /// Updating the UI with the retrieved value
//                        self?.heartRateLabel.text = "\(Int(heartRate))"
//                    }
//                })
//        }
//    }
    
//    public func fetchLatestHeartRateSample() -> HKQuantitySample {
//
//        /// Create sample type for the heart rate
//        guard let sampleType = HKObjectType
//            .quantityType(forIdentifier: .heartRate) else {
//                throw
//        }
//
//        /// Predicate for specifiying start and end dates for the query
//        let predicate = HKQuery
//            .predicateForSamples(
//                withStart: Date.distantPast,
//                end: Date(),
//                options: .strictEndDate)
//
//        /// Set sorting by date.
//        let sortDescriptor = NSSortDescriptor(
//            key: HKSampleSortIdentifierStartDate,
//            ascending: false)
//
//        /// Create the query
//        let query = HKSampleQuery(
//            sampleType: sampleType,
//            predicate: predicate,
//            limit: Int(HKObjectQueryNoLimit),
//            sortDescriptors: [sortDescriptor]) { (_, results, error) in
//
//                guard error == nil else {
//                    print("Error: \(error!.localizedDescription)")
//                    return
//                }
//
////                return results?[0] as? HKQuantitySample
//        }
//
//        self.healthStore.execute(query)
//    }
}
