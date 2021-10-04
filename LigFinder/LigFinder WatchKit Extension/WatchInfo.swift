//
//  WatchInfo.swift
//  LigFinder WatchKit Extension
//
//  Created by Emil Neirup Jensen on 29/04/2021.
//

import CoreData

class WatchInfo: NSManagedObject {
    @NSManaged var isConnected: Bool
    @NSManaged var name: String
    @NSManaged var id: Int32
}
