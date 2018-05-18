//
//  DBManager.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 16/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import RealmSwift
import MapKit
import GeoQueries

class DBManager {
    private var database: Realm
    
    static let sharedInstance = DBManager()
    
    private init() {
        database = try! Realm()
    }
    
    func addLocation(location: UserLocation) {
        try! self.database.write {
            self.database.add(location)
            print("Add location: ", location.heartRate)
            print("Added new location")
        }
    }
    
    func getPointsInRegion(region: MKCoordinateRegion) -> Results<UserLocation> {
        return try! database.findInRegion(type: UserLocation.self, region: region)
    }
    
    func findNearby(lat: Double, lon: Double, radius: Double) -> [UserLocation] {
        return try! database.findNearby(type: UserLocation.self, origin: CLLocationCoordinate2D(latitude: lat, longitude: lon), radius: radius, sortAscending: nil)
    }
    
    func startTraining(trening: Trening) {
        try! self.database.write {
            self.database.add(trening)
            print("Saved new trening")
        }
    }
    
    func getCurrentTrening() -> Results<Trening> {
        return try! self.database.objects(Trening.self).filter("inProggres", true)
    }
}


