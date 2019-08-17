//
//  TimeResult.swift
//  Timer
//
//  Created by user on 17.08.2019.
//  Copyright © 2019 user. All rights reserved.
//

import Foundation
import CoreData

@objc(TimeResult)
public class TimeResult: NSManagedObject {
    
}

extension TimeResult {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeResult> {
        return NSFetchRequest<TimeResult>(entityName: "TimeResult")
    }
    
    @NSManaged public var round: Int32
    @NSManaged public var timeResult: Double
    
}
