//
//  ViewController.swift
//  SampleDropDownMenu
//
//  Created by Justin M Platz on 5/27/16.
//  Copyright © 2016 Justin M Platz. All rights reserved.
//

import UIKit
import Foundation
import TextToSpeechV1
import SpeechToTextV1
import CoreData

let textToSpeechUsername = "045af1d1-414a-42df-be6c-d7c27769de42"
let textToSpeechpassword = "hL7E20iT07wg"
let textToSpeech = TextToSpeech(username: textToSpeechUsername, password: textToSpeechpassword)

let speechToTextUsername = "fa894029-1f25-49ba-979d-9f6919abb9e5"
let speechToTextPassword = "1WpwawZAkbGI"
let speechToText = SpeechToText(username: speechToTextUsername, password: speechToTextPassword)

var currentController = "Ask"
let watsonCloseDuration  = 1.0

let faceRecognitionEndpoint = "https://nbainfo.watson.ibm.com:5000/search_face_iOS"
//let faceRecognitionEndpoint = "https://9.2.48.171:5000/search_face_iOS"

let dialogEndpoint = "https://nbainfo.watson.ibm.com:5000/chitchat/"
//let dialogEndpoint = "https://9.2.53.202:5000/chitchat/"

var userName = checkCoreDataForUserName()

func checkCoreDataForUserName() -> String{
    let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
    
    let managedContext = appDelegate.managedObjectContext
    
    let userRequest = NSFetchRequest(entityName: "User")
    var fetchError : NSError?
    if let userResult = try! managedContext.executeFetchRequest(userRequest) as? [User] {
        if userResult.count == 0 {
            print("No person found")
        }
        if userResult.count == 1 {
            for user in userResult{
                return user.name!
            }
        }
            
        else {
            print("Persons found: \(userResult.count)")
        }
    } else {
        print("fetch failed: \(fetchError!.localizedDescription)")
    }
    return "Error No Name"
}


func saveName(name: String) {
    let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
    
    let managedContext = appDelegate.managedObjectContext
    
    let userRequest = NSFetchRequest(entityName: "User")
    
    if let userResult = try! managedContext.executeFetchRequest(userRequest) as? [User] {
        
        if userResult.count == 0 {
            let entity =  NSEntityDescription.entityForName("User",
                                                            inManagedObjectContext:managedContext)
            
            let person = NSManagedObject(entity: entity!,
                                         insertIntoManagedObjectContext: managedContext)
            
            person.setValue(name, forKey: "name")
            
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        
        if userResult.count == 1 {
            for user in userResult{
                user.name = name
                //4
                do {
                    try managedContext.save()
                    //5
                } catch let error as NSError  {
                    print("Could not save \(error), \(error.userInfo)")
                }
            }
        }
        
    }
}



//http://debater.mybluemix.net/sports_sms_answer/question text goes here
//http://debater.mybluemix.net/db_name_add/first,last
//sendHTTPGETRequestToNameAdd("http://debater.mybluemix.net/db_name_add/", first: "justin", last: "pmanjones")
func sendHTTPGETRequestToNameAdd(scriptURL: String, first: String, last: String) -> Void{
    
    let fullURL = scriptURL + first + "," + last
    
    // Create NSURL Ibject
    let getURL = NSURL(string: fullURL)
    
    // Creaste URL Request
    let request = NSMutableURLRequest(URL: getURL!)
    
    // Set request HTTP method to GET. It could be POST as well
    request.HTTPMethod = "GET"
    
    // Excute HTTP Request
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
        data, response, error in
        
        // Check for error
        if error != nil
        {
            print("error=\(error)")
            return
        }
        
        // Print out response string
        let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
        print("responseString = \(responseString)")
        
        
        // Convert server json response to NSDictionary
        do {
            if let convertedJsonIntoDict = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                
                // Print out dictionary
                print(convertedJsonIntoDict)
                
                // Get value by key
                let firstNameValue = convertedJsonIntoDict["userName"] as? String
                print(firstNameValue!)
                
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }
    
    task.resume()
}




