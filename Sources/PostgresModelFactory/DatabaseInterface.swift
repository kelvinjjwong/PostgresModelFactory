//
//  File.swift
//  
//
//  Created by kelvinwong on 2023/11/12.
//

import Foundation


public protocol DBExecutor {
    func execute(sql:String) throws
    func count(sql:String) throws -> Int
}

public protocol DatabaseInterface : DBExecutor {
    
    func connect() throws
    func execute(sql: String) throws
    func execute(sql: String, parameterValues:[DatabaseValueConvertible?]) throws
    func execute(statement: SQLStatement) throws
    func delete<T:Codable & EncodableDBRecord>(object:T, table:String, primaryKeys:[String]) throws
    func save<T:Codable & EncodableDBRecord>(object:T, table:String, primaryKeys:[String], autofillColumns:[String]) throws
    func query<T:Codable & EncodableDBRecord>(object:T, table:String, sql:String, values:[DatabaseValueConvertible?], offset:Int?, limit:Int?) throws -> [T]
    func query<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, orderBy:String, values:[DatabaseValueConvertible?], offset:Int?, limit:Int?) throws -> [T]
    func query<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?], orderBy:String) throws -> [T]
    func queryOne<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, orderBy:String, values:[DatabaseValueConvertible?]) throws -> T?
    func queryOne<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?]) throws -> T?
    func queryOne<T:Codable & EncodableDBRecord>(object:T, table:String, sql:String, values:[DatabaseValueConvertible?]) throws -> T?
    func count(sql:String) throws -> Int
    func count(sql:String, parameterValues: [DatabaseValueConvertible?]) throws -> Int
    func count<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?]) throws -> Int
    func count<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, values:[DatabaseValueConvertible?]) throws -> Int
    func queryTableInfo(table:String, schema:String) throws -> TableInfo
    func queryTableInfos(schema:String) throws -> [TableInfo]
}
