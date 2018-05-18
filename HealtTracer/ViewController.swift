//
//  ViewController.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 16/04/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UITableView {
    
//    fileprivate let healthKitManager = HealtKitManager.sharedInstance
    fileprivate var steps = [HKQuantitySample]()
    
    fileprivate let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        requestHealthAuthorization()
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
}

//private extension ViewController {
//    func requestHealthAuthorization() {
//        let dataTypesToRead = NSSet(object: healthKitManager.stepsCount as Any)
//        healthKitManager.healthStore?.requestAuthorization(toShare:nil, read: dataTypesToRead as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
//            if success {
//                self.querySteps()
//            } else {
//                print(error.debugDescription)
//            }
//        })
//    }
//
//    func querySteps() {
//        let sampleQuery = HKSampleQuery(sampleType: healthKitManager.stepsCount!,
//                                        predicate: nil,
//                                        limit: 100,
//                                        sortDescriptors: nil)
//        { [unowned self] (query, results, error) in
//            if let results = results as? [HKQuantitySample] {
//                self.steps = results
//            }
//        }
//
//        healthKitManager.healthStore?.execute(sampleQuery)
//    }
//}

