//
//  TracerLocation.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 16/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import UIKit
import MapKit

class TracerLocation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var heartRate: Double?
    
    init(_ latitude:CLLocationDegrees, _ longitude:CLLocationDegrees, title:String, subtitle:String, heartRate: Double){
        self.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        self.title = title
        self.subtitle = subtitle
        self.heartRate = heartRate
    }
}
