//
//  Trening.swift
//  HealtTracer
//
//  Created by Karol Kozakowski on 17/05/2018.
//  Copyright © 2018 Karol Kozakowski. All rights reserved.
//

import Foundation
import RealmSwift

class Trening: Object {
    @objc dynamic var StartDate = Date()
    @objc dynamic var EndDate = Date()
    @objc dynamic var inProggres = true
}
