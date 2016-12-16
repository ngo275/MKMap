//
//  Data+CoreDataProperties.swift
//  MKMap
//
//  Created by ShuichiNagao on 2016/12/13.
//  Copyright © 2016 ShuichiNagao. All rights reserved.
//

import Foundation
import CoreData


extension Data {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Data> {
        return NSFetchRequest<Data>(entityName: "Data");
    }

    @NSManaged public var lat: NSNumber?
    @NSManaged public var lon: NSNumber?
    @NSManaged public var date: Date

}
