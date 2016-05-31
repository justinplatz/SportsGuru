//
//  Helper.swift
//  SampleDropDownMenu
//
//  Created by Justin M Platz on 5/27/16.
//  Copyright © 2016 Justin M Platz. All rights reserved.
//

import Foundation

import TextToSpeechV1
import SpeechToTextV1
import AlchemyLanguageV1

let textToSpeechUsername = "c4cb05f9-6a5a-44d7-9cd9-53812fb269c4"
let textToSpeechpassword = "bDwoUiTY5Ntu"
let textToSpeech = TextToSpeech(username: textToSpeechUsername, password: textToSpeechpassword)

let speechToTextUsername = "bf028ea6-3dc5-4e1e-890c-84fdbfbb9d7c"
let speechToTextPassword = "tp4WNbINNSp1"
let speechToText = SpeechToText(username: speechToTextUsername, password: speechToTextPassword)

let alchemyAPIKey = "34d4598a1ea843ade648564432e8d865b8f198d2"
let alchemyLanguage = AlchemyLanguage(apiKey: alchemyAPIKey)