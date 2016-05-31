/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import ObjectMapper

/**
 
 **ConceptResponse**
 
 Returned by the AlchemyLanguage service.
 
 */
public struct ConceptResponse: AlchemyLanguageGenericModel, Mappable {
    
    // MARK: AlchemyGenericModel
    public var totalTransactions: Int?
    
    // MARK: AlchemyLanguageGenericModel
    public var language: String?
    public var url: String?
    
    // MARK: Concepts
    /** returned concepts (see **Concept** class)*/
    public var concepts: [Concept]?
    
    
    public init?(_ map: Map) {}
    
    public mutating func mapping(map: Map) {
        
        // alchemyGenericModel
        totalTransactions <- map[""]
        
        // alchemyLanguageGenericModel
        language <- map["language"]
        url <- map["url"]
        
        // concept
        concepts <- map["concepts"]
        
    }
    
}
