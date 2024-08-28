//
//  DatabaseProfile.swift
//
//  Created by kelvinwong on 2023/10/22.
//  Copyright © 2023 nonamecat. All rights reserved.
//

import Foundation

public class DatabaseProfile : Codable {
    
    var engine = ""
    var selected = false
    
    var host = ""
    var port:Int = 0
    var user = ""
    var database = ""
    var schema = ""
    var password = ""
    var nopsw = true
    var ssl = false
    
    public init() {}
    
    public func id() -> String {
        return "\(engine):\(host):\(database):\(schema)"
    }
    
    public func toJSON() -> String {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(self)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            return json ?? "{}"
        }catch{
            print(error)
            return "{}"
        }
    }
    
    public static func fromJSON(_ jsonString:String) -> DatabaseProfile? {
        let jsonDecoder = JSONDecoder()
        do{
            return try jsonDecoder.decode(DatabaseProfile.self, from: jsonString.data(using: .utf8)!)
        }catch{
            print(error)
            return nil
        }
    }
}
