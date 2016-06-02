//
//  DataController.swift
//  SampleDropDownMenu
//
//  Created by Justin M Platz on 6/2/16.
//  Copyright © 2016 Justin M Platz. All rights reserved.
//

import UIKit

import CoreData
class DataController: NSObject {
    
    var managedObjectContext: NSManagedObjectContext
    
    override  init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = NSBundle.mainBundle().URLForResource("Up_and_Running_With_Core_Data", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        self.managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        self.managedObjectContext.persistentStoreCoordinator = psc
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        let docURL = urls[urls.endIndex-1]
        
        /* The directory the application uses to store the Core Data store file.
         This code uses a file named "DataModel.sqlite" in the application's documents directory.
         */
        let storeURL = docURL.URLByAppendingPathComponent("Up_and_Running_With_Core_Data.sqlite")
        do {
            try psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch {
            fatalError("Error migrating store: \(error)")
        }
        
    }
}