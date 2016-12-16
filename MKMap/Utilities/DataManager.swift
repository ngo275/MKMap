//
//  DataController.swift
//  MKMap
//
//  Created by ShuichiNagao on 2016/12/13.
//  Copyright © 2016 ShuichiNagao. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class DataManager {
    static let shared = DataManager()
    
    func save() {
        let locs = LocationManager.shared.locationDataArray
        
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext
        let data = NSEntityDescription.entity(forEntityName: "Data", in: viewContext)
        guard let d = data else {
            return
        }
        
        locs.forEach { (loc) in
            let newRecord = NSManagedObject(entity: d, insertInto: viewContext)
            newRecord.setValue(loc.coordinate.latitude, forKey: "lat")
            newRecord.setValue(loc.coordinate.longitude, forKey: "lon")
            newRecord.setValue(loc.timestamp, forKey: "date")
            
            do {
                try viewContext.save()
            } catch {
                
            }
        }
        /*バルクインサートしたい
        do {
            try viewContext.save()
        } catch {
            
        }*/

    }
    
    func read() -> [Data]? {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext
        let query: NSFetchRequest<Data> = Data.fetchRequest()
        
        do {
            let fetchResults = try viewContext.fetch(query)
            for result: AnyObject in fetchResults {
//                let lat: Double? = result.value(forKey: "lat") as? Double
//                let lon: Double? = result.value(forKey: "lon") as? Double
//                let date: Date? = result.value(forKey: "date") as? Date
                print("----------------\(result)")
                
            }
            return fetchResults
            
        } catch {
            return nil
        }
    }
    
    func update() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Data> = Data.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            for result: AnyObject in fetchResults {
                let record = result as! NSManagedObject
                record.setValue(Date(), forKey: "created_at")
            }
            try viewContext.save()
        } catch {
        }
    }

    func delete() {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let viewContext = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Data> = Data.fetchRequest()
        do {
            let fetchResults = try viewContext.fetch(request)
            for result: AnyObject in fetchResults {
                let record = result as! NSManagedObject
                viewContext.delete(record)
            }
            try viewContext.save()
        } catch {
        }
    }
    
}
