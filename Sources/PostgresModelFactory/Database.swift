//
//  File.swift
//  
//
//  Created by kelvinwong on 2023/11/12.
//

import Foundation

public class Database : DatabaseInterface {
    
    private let impl:DatabaseInterface
    
    public init(profile:DatabaseProfile) {
        if profile.engine == "PostgreSQL" {
            self.impl = PostgresDB(databaseProfile: profile)
        }else{
            fatalError("Unsupported engine [\(profile.engine)]")
        }
    }
    
    public func connect() throws {
        try self.impl.connect()
    }
    
    public func execute(sql: String) throws {
        try self.impl.execute(sql: sql)
    }
    
    public func execute(sql: String, parameterValues: [DatabaseValueConvertible?]) throws {
        try self.impl.execute(sql: sql, parameterValues: parameterValues)
    }
    
    public func execute(statement: SQLStatement) throws {
        try self.impl.execute(statement: statement)
    }
    
    public func delete<T>(object: T, table: String, primaryKeys: [String]) throws where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.delete(object: object, table: table, primaryKeys: primaryKeys)
    }
    
    public func save<T>(object: T, table: String, primaryKeys: [String], autofillColumns: [String]) throws where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.save(object: object, table: table, primaryKeys: primaryKeys, autofillColumns: autofillColumns)
    }
    
    public func query<T>(object: T, table: String, sql: String, values: [DatabaseValueConvertible?], offset: Int?, limit: Int?) throws -> [T] where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.query(object: object, table: table, sql: sql, values: values, offset: offset, limit: limit)
    }
    
    public func query<T>(object: T, table: String, where whereSQL: String, orderBy: String, values: [DatabaseValueConvertible?], offset: Int?, limit: Int?) throws -> [T] where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.query(object: object, table: table, where: whereSQL, orderBy: orderBy, values: values, offset: offset, limit: limit)
    }
    
    public func query<T>(object: T, table: String, parameters: [String : DatabaseValueConvertible?], orderBy: String) throws -> [T] where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.query(object: object, table: table, parameters: parameters, orderBy: orderBy)
    }
    
    public func queryOne<T>(object: T, table: String, where whereSQL: String, orderBy: String, values: [DatabaseValueConvertible?]) throws -> T? where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.queryOne(object: object, table: table, where: whereSQL, orderBy: orderBy, values: values)
    }
    
    public func queryOne<T>(object: T, table: String, parameters: [String : DatabaseValueConvertible?]) throws -> T? where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.queryOne(object: object, table: table, parameters: parameters)
    }
    
    public func queryOne<T>(object: T, table: String, sql: String, values: [DatabaseValueConvertible?]) throws -> T? where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.queryOne(object: object, table: table, sql: sql, values: values)
    }
    
    public func count(sql: String) throws -> Int {
        try self.impl.count(sql: sql)
    }
    
    public func count(sql: String, parameterValues: [DatabaseValueConvertible?]) throws -> Int {
        try self.impl.count(sql: sql, parameterValues: parameterValues)
    }
    
    public func count<T>(object: T, table: String, parameters: [String : DatabaseValueConvertible?]) throws -> Int where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.count(object: object, table: table, parameters: parameters)
    }
    
    public func count<T>(object: T, table: String, where whereSQL: String, values: [DatabaseValueConvertible?]) throws -> Int where T : EncodableDBRecord, T : Decodable, T : Encodable {
        try self.impl.count(object: object, table: table, where: whereSQL, values: values)
    }
    
    public func queryTableInfo(table: String, schema: String) throws -> TableInfo {
        try self.impl.queryTableInfo(table: table, schema: schema)
    }
    
    public func queryTableInfos(schema: String) throws -> [TableInfo] {
        try self.impl.queryTableInfos(schema: schema)
    }
}
