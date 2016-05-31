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
import Freddy

public extension Dictionary {
    
    public func map<OutValue>(@noescape transform: Value throws -> OutValue) rethrows -> [Key: OutValue] {
        var dictionary = [Key: OutValue]()
        for (k, v) in self {
            dictionary[k] = try transform(v)
        }
        return dictionary
    }
}

public extension JSON {
    
    /// An error that occurred during serialization.
    public enum SerializationError: ErrorType {
        case SerializationError
    }
    
    /**
     Attempt to serialize `JSON` into a `String`.
     
     - returns: A String containing the `JSON`.
     - throws: Errors that arise from `NSJSONSerialization`.
     */
    public func serializeString() throws -> Swift.String {
        let data = try self.serialize()
        guard let string = Swift.String(data: data, encoding: NSUTF8StringEncoding) else {
            throw SerializationError.SerializationError
        }
        return string
    }
}
