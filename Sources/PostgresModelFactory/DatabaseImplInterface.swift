//
//  DatabaseImplInterface.swift
//  
//
//  Created by kelvinwong on 2023/11/16.
//

import Foundation

public protocol DatabaseImplInterface {
    func connect() throws
    func execute(statement: SQLStatement) throws
    func query<T:Codable & EncodableDBRecord>(object:T, table:String, sql:String, values:[DatabaseValueConvertible?]) throws -> [T]
    func count(sql:String, parameterValues: [DatabaseValueConvertible?]) throws -> Int
    func queryExist(existsStatement:SQLStatement) throws -> Bool
}
