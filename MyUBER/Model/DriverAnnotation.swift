//
//  DriverAnnotation.swift
//  MyUBER
//
//  Created by admin on 20.06.2022.
//

import MapKit

class DriverAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var uid: String

    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }

}
