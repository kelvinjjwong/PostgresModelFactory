//
//  DatabaseProfile.swift
//
//  Created by kelvinwong on 2023/10/22.
//  Copyright © 2023 nonamecat. All rights reserved.
//

import Foundation

public class DatabaseProfile : Codable {
    
    public var engine = ""
    public var selected = false
    
    public var host = ""
    public var port:Int = 0
    public var user = ""
    public var database = ""
    public var schema = ""
    public var password = ""
    public var passwordEncryptMethod = ""
    public var nopsw = true
    public var ssl = false
    public var socketTimeoutInSeconds = 0
    
    public init() {}
    
    public func id() -> String {
        return "\(engine):\(host):\(port):\(database):\(schema)"
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
