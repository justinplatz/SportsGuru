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
