//
//  LocationMark.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 12/06/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation

import RealmSwift
import MapKit

class LocationMark: Object {
    @objc dynamic var lat: Double = 0
    @objc dynamic var lng: Double = 0
    var trening: Trening = Trening()
    
    @objc dynamic var meanHeartRate: Double = 0
}
