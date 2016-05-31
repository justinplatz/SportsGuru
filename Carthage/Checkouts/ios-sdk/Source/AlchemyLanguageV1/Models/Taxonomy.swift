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
 
 **Taxonomy**
 
 Child class of Taxonomies
 
 */
public struct Taxonomy: Mappable {
    
    /** confidence in result: 0 or 1 */
    public var confident: Int?

    /**  category of taxonomy */
    public var label: String?

    /** confidence score for detected category, 0.0 to 1.0, higher is better */
    public var score: Double?
    
    
    public init?(_ map: Map) {}
    
    public mutating func mapping(map: Map) {
        
        confident <- (map["confident"], Transformation.stringToInt)
        label <- map["label"]
        score <- (map["score"], Transformation.stringToDouble)
        
    }
    
}
