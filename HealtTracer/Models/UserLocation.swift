//
//  Location.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 16/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import RealmSwift
import MapKit

class UserLocation: Object {
    
    @objc dynamic var lng = 0.0
    @objc dynamic var lat = 0.0
    @objc dynamic var heartRate = 0.0
    @objc dynamic var locationDate = Date()
    
    @objc dynamic var trening: Trening?
}
