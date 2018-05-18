//
//  healthKitManager.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 16/04/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import HealthKit

class HealtKitManager {
    let healthKitStore = HKHealthStore()
    
    func getHeartRate(completion: @escaping (Double) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[heartRateType], completion:{(success, error) in
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
                        let hrLatest = results?[0] as! HKQuantitySample
                        
                        let heartRateUnit = HKUnit(from: "count/min")
                        let heartRate = hrLatest
                            .quantity
                            .doubleValue(for: heartRateUnit)
                        
                        completion(heartRate)
                        
                }
                
                self.healthKitStore.execute(query)
            })
        }
    }
    
    func readFloors(result: @escaping (Double) -> Void) {
        let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed)
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[quantityType!], completion:{(success, error) in

                let date = Date()
                let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                let newDate = cal.startOfDay(for: date)
                
                let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)

                let floorsClimbedQuery = HKStatisticsQuery(quantityType: quantityType!, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, results, errro) in
                    guard let results = results else {
                        result(0)
                        return
                    }
                    
                    var floors = 0.0
                    
                    if let quantity = results.sumQuantity() {
                        let unit = HKUnit.count()
                        floors = quantity.doubleValue(for: unit)
                        result(floors)
                    }
                }
                
                self.healthKitStore.execute(floorsClimbedQuery)
            })
        }
    }
    
    func readActiveHours(result: @escaping (Double) -> Void) {
        let objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType()
        ]
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:objectTypes, completion:{(success, error) in
                
                // Create the date components for the predicate
                guard let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian) else {
                    fatalError("*** This should never fail. ***")
                }
                
                let endDate = NSDate()
                
                guard let startDate = calendar.date(byAdding: .day, value: -1, to: endDate as Date, options: []) else {
                    fatalError("*** unable to calculate the start date ***")
                }
                
                let units: NSCalendar.Unit = [.day, .month, .year, .era]
                
                var startDateComponents = calendar.components(units, from: startDate)
                startDateComponents.calendar = calendar as Calendar
                
                var endDateComponents = calendar.components(units, from: endDate as Date)
                endDateComponents.calendar = calendar as Calendar
                
                
                // Create the predicate for the query
                let summariesWithinRange = HKQuery.predicate(forActivitySummariesBetweenStart: startDateComponents, end: endDateComponents)
                
                // Build the query
                let query = HKActivitySummaryQuery(predicate: summariesWithinRange) { (query, summaries, error) -> Void in
                    guard let activitySummaries = summaries else {
                        guard error != nil else {
                            fatalError("*** Did not return a valid error object. ***")
                        }
                        print("Error")
                        return
                    }
                    
                    // Do something with the summaries here...
//                    let activity = activitySummaries[0]
                    guard let activity = activitySummaries.first else {
                        print("Error")
                        result(0.0)
                        return
                    }
                    let activityHours = activity.appleStandHours
                    
                    result(activityHours.doubleValue(for: HKUnit.count()))
                }
                
                self.healthKitStore.execute(query)
            })
        }
    }
    
    func readWeight(result: @escaping (Double) -> Void) {
        let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[quantityType!], completion:{(success, error) in
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "hh:mm:ss"
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/YYYY"
                
                let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
                
                let sortDescriptor = NSSortDescriptor(
                    key: HKSampleSortIdentifierStartDate,
                    ascending: false)
                
                let bodyMassQuery = HKSampleQuery(sampleType: quantityType!, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (query, results, errro) in
                    guard let results = results else {
                        result(0)
                        return
                    }
                    guard let bodyMassFirst = results.first as? HKQuantitySample else {
                        result(0)
                        return
                    }
//                    let bodyMassFirst = results.first as! HKQuantitySample
                    
                    let kg = HKUnit.gramUnit(with: .kilo)
                    let bodyMass = bodyMassFirst
                        .quantity
                        .doubleValue(for: kg)
                    
                    result(bodyMass)
                    
                }
                
                self.healthKitStore.execute(bodyMassQuery)
            })
        }
    }
    
    func readActiveEnergy(result: @escaping (Double, Double) -> Void) {
        let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[quantityType!], completion:{(success, error) in
                
                // Create the date components for the predicate
                guard let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian) else {
                    fatalError("*** This should never fail. ***")
                }
                
                let endDate = NSDate()
                
                guard let startDate = calendar.date(byAdding: .day, value: 0, to: endDate as Date, options: []) else {
                    fatalError("*** unable to calculate the start date ***")
                }
                
                let units: NSCalendar.Unit = [.day, .month, .year, .era]
                
                var startDateComponents = calendar.components(units, from: startDate)
                startDateComponents.calendar = calendar as Calendar
                
                var endDateComponents = calendar.components(units, from: endDate as Date)
                endDateComponents.calendar = calendar as Calendar
                
                
                // Create the predicate for the query
                let summariesWithinRange = HKQuery.predicate(forActivitySummariesBetweenStart: startDateComponents, end: endDateComponents)
                
                // Build the query
                let query = HKActivitySummaryQuery(predicate: summariesWithinRange) { (query, summaries, error) -> Void in
                    guard let activitySummaries = summaries else {
                        guard error != nil else {
                            fatalError("*** Did not return a valid error object. ***")
                        }
                        print("Error")
                        return
                    }
                    
                    // Do something with the summaries here...
//                    let activity = activitySummaries[0]
                    guard let activity = activitySummaries.first else {
                        result(0,0)
                        return
                    }
                    let activityHours = activity.activeEnergyBurned
                    let activityEnergyGoal = activity.activeEnergyBurnedGoal
                    let ahR = activityHours.doubleValue(for: HKUnit.largeCalorie())
                    let goal = activityEnergyGoal.doubleValue(for: HKUnit.largeCalorie())
                    
                    result(ahR, goal)
                }
                
                self.healthKitStore.execute(query)
            })
        }
    }
    
    func readDistance(result: @escaping (Double, Double) -> Void) {
        let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[quantityType!], completion:{(success, error) in
                
                let date = Date()
                let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                let newDate = cal.startOfDay(for: date)
                
                let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)
                
                let floorsClimbedQuery = HKStatisticsQuery(quantityType: quantityType!, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, results, errro) in
                    guard let results = results else {
                        result(0, 0)
                        return
                    }
                    
                    var floors = 0.0
                    
                    if let quantity = results.sumQuantity() {
                        let km = HKUnit.meterUnit(with: .kilo)
                        floors = quantity.doubleValue(for: km)
                        result(floors, 0)
                    }
                }
                
                self.healthKitStore.execute(floorsClimbedQuery)
            })
        }
    }
    
    func readSteps(result: @escaping (Double, Double) -> Void) {
        let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[quantityType!], completion:{(success, error) in
                
                let date = Date()
                let cal = Calendar(identifier: Calendar.Identifier.gregorian)
                let newDate = cal.startOfDay(for: date)
                
                let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: .strictStartDate)
                
                let floorsClimbedQuery = HKStatisticsQuery(quantityType: quantityType!, quantitySamplePredicate: predicate, options: .cumulativeSum) { (query, results, errro) in
                    guard let results = results else {
                        result(0, 0)
                        return
                    }
                    
                    var floors = 0.0
                    
                    if let quantity = results.sumQuantity() {
                        let unit = HKUnit.count()
                        floors = quantity.doubleValue(for: unit)
                        result(floors, 0)
                    }
                }
                
                self.healthKitStore.execute(floorsClimbedQuery)
            })
        }
    }
    
    func getStepsCountIn7Days(result: @escaping (Double) -> Void) {
        let stepCountIdentifier = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[stepCountIdentifier], completion:{(success, error) in
     
                let typeHeart = HKQuantityType.quantityType(forIdentifier: .stepCount)
                let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: Date().startOfWeek , end: Date(), options: .strictStartDate)
                
                let squery = HKStatisticsQuery(quantityType: typeHeart!, quantitySamplePredicate: predicate, options: .cumulativeSum) {(query, results, error) in
                    guard let results = results else {
                        result(0)
                        return
                    }
                    
                    var steps = 0.0
                    if let quantity = results.sumQuantity() {
                        let unit = HKUnit.count()
                        steps = quantity.doubleValue(for: unit)
                        result(steps)
                    }
                }
                self.healthKitStore.execute(squery)
            })
        }
    }
    
    func getDistanceIn7Days(result: @escaping (Double) -> Void) {
        let stepCountIdentifier = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[stepCountIdentifier], completion:{(success, error) in
                
                let typeHeart = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
                let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: Date().startOfWeek , end: Date(), options: .strictStartDate)
                
                let squery = HKStatisticsQuery(quantityType: typeHeart!, quantitySamplePredicate: predicate, options: .cumulativeSum) {(query, results, error) in
                    guard let results = results else {
                        result(0)
                        return
                    }
                    
                    var distance = 0.0
                    if let quantity = results.sumQuantity() {
                        let km = HKUnit.meterUnit(with: .kilo)
                        distance = quantity.doubleValue(for: km)
                        result(distance)
                    }
                }
                self.healthKitStore.execute(squery)
            })
        }
    }
    
    func getCaloriesIn7days(result: @escaping (Double) -> Void) {
        let stepCountIdentifier = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
        
        if HKHealthStore.isHealthDataAvailable() {
            self.healthKitStore.requestAuthorization(toShare: nil, read:[stepCountIdentifier], completion:{(success, error) in
                
                let typeHeart = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
                let predicate: NSPredicate? = HKQuery.predicateForSamples(withStart: Date().startOfWeek , end: Date(), options: .strictStartDate)
                
                let squery = HKStatisticsQuery(quantityType: typeHeart!, quantitySamplePredicate: predicate, options: .cumulativeSum) {(query, results, error) in
                    guard let results = results else {
                        result(0)
                        return
                    }
                    
                    var calories = 0.0
                    if let quantity = results.sumQuantity() {
                        calories = quantity.doubleValue(for: HKUnit.largeCalorie())
                        result(calories)
                    }
                }
                self.healthKitStore.execute(squery)
            })
        }
    }
}

extension Calendar {
    static let gregorian = Calendar(identifier: .gregorian)
}
extension Date {
    var startOfWeek: Date? {
        return Calendar.gregorian.date(from: Calendar.gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
    }
}
