//
//  PostgresRecord.swift
//  ImageDocker
//
//  Created by Kelvin Wong on 2020/4/26.
//  Copyright © 2020 nonamecat. All rights reserved.
//

import Foundation
import LoggerFactory
import PostgresClientKit

public protocol DatabaseRecord : Codable, EncodableDBRecord {
    
    init()
    
    func save(_ db: DatabaseInterface) throws
    
    func table() -> String
    
    func primaryKeys() -> [String]
    
    func autofillColumns() -> [String]
}

extension DatabaseRecord {
    
    private func exists(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?]) throws -> Bool {
        let count = try self.count(db, parameters: parameters)
        if count > 0 {
            return true
        }else{
            return false
        }
    }
    
    public func save(_ db: DatabaseInterface) throws {
        try db.save(object: self, table: self.table(), primaryKeys: self.primaryKeys(), autofillColumns: self.autofillColumns())
    }
    
    public func delete(_ db: DatabaseInterface, keyColumns:[String] = []) throws {
        try db.delete(object: self, table: self.table(), primaryKeys: keyColumns.count > 0 ? keyColumns : self.primaryKeys())
    }
    
    private func count(_ db: DatabaseInterface) throws -> Int {
        return try db.count(object: self, table: self.table(), parameters: [:])
    }
    
    private func count(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?]) throws -> Int {
        return try db.count(object: self, table: self.table(), parameters: parameters)
    }
    
    private func count(_ db: DatabaseInterface, where whereSQL:String, parameters: [DatabaseValueConvertible?] = []) throws -> Int {
        return try db.count(object: self, table: self.table(), where: whereSQL, values: parameters)
    }
    
    private func fetchOne(_ db: DatabaseInterface) throws -> Self? {
        return try db.queryOne(object: self, table: self.table(), parameters: [:])
    }
    
    private func fetchOne(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?]) throws -> Self? {
        return try db.queryOne(object: self, table: self.table(), parameters: parameters)
    }
    
    private func fetchOne(_ db: DatabaseInterface, where whereSQL:String, orderBy:String = "", values:[DatabaseValueConvertible?] = []) throws -> Self? {
        return try db.queryOne(object: self, table: self.table(), where: whereSQL, orderBy: orderBy, values: values)
    }
    
    private func fetchOne(_ db: DatabaseInterface, sql: String, values:[DatabaseValueConvertible?] = []) throws -> Self? {
        return try db.queryOne(object: self, table: self.table(), sql: sql, values: values)
    }
    
    private func fetchAll(_ db: DatabaseInterface, orderBy:String = "") throws -> [Self] {
        return try db.query(object: self, table: self.table(), parameters: [:], orderBy: orderBy)
    }
    
    private func fetchAll(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?], orderBy: String = "") throws -> [Self] {
        return try db.query(object: self, table: self.table(), parameters: parameters, orderBy: orderBy)
    }
    
    private func fetchAll(_ db: DatabaseInterface, where whereSQL:String, orderBy:String = "", values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [Self] {
        return try db.query(object: self, table: self.table(), where: whereSQL, orderBy: orderBy, values: values, offset: offset, limit: limit)
    }
    
    private func fetchAll(_ db: DatabaseInterface, sql: String, values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [Self] {
        return try db.query(object: self, table: self.table(), sql: sql, values: values, offset: offset, limit: limit)
    }
}

extension DatabaseRecord {
    
    public static func exists(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?]) throws -> Bool {
        let obj = Self.init()
        return try obj.exists(db, parameters: parameters)
    }
    
    public static func count(_ db: DatabaseInterface) throws -> Int {
        let obj = Self.init()
        return try obj.count(db)
    }
    
    public static func count(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?]) throws -> Int {
        let obj = Self.init()
        return try obj.count(db, parameters: parameters)
    }
    
    public static func count(_ db: DatabaseInterface, where whereSQL:String, parameters: [DatabaseValueConvertible?] = []) throws -> Int {
        let obj = Self.init()
        return try obj.count(db, where: whereSQL, parameters: parameters)
    }
    
    public static func fetchOne(_ db: DatabaseInterface) throws -> Self? {
        let obj = Self.init()
        return try obj.fetchOne(db)
    }
    
    public static func fetchOne(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?]) throws -> Self? {
        let obj = Self.init()
        return try obj.fetchOne(db, parameters: parameters)
    }
    
    public static func fetchOne(_ db: DatabaseInterface, where whereSQL:String, orderBy:String = "", values:[DatabaseValueConvertible?] = []) throws -> Self? {
        let obj = Self.init()
        return try obj.fetchOne(db, where: whereSQL, orderBy: orderBy, values: values)
    }
    
    public static func fetchOne(_ db: DatabaseInterface, sql: String, values:[DatabaseValueConvertible?] = []) throws -> Self? {
        let obj = Self.init()
        return try obj.fetchOne(db, sql: sql, values: values)
    }
    
    public static func fetchAll(_ db: DatabaseInterface, orderBy: String = "") throws -> [Self] {
        let obj = Self.init()
        return try obj.fetchAll(db, orderBy: orderBy)
    }
    
    public static func fetchAll(_ db: DatabaseInterface, parameters: [String : DatabaseValueConvertible?], orderBy: String = "") throws -> [Self] {
        let obj = Self.init()
        return try obj.fetchAll(db, parameters: parameters, orderBy: orderBy)
    }
    
    public static func fetchAll(_ db: DatabaseInterface, where whereSQL:String, orderBy:String = "", values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [Self] {
        let obj = Self.init()
        return try obj.fetchAll(db, where: whereSQL, orderBy: orderBy, values: values, offset: offset, limit: limit)
    }
    
    public static func fetchAll(_ db: DatabaseInterface, sql:String, values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [Self] {
        let obj = Self.init()
        return try obj.fetchAll(db, sql: sql, values: values, offset: offset, limit: limit)
    }
}

extension DatabaseRecord {

    public func table() -> String {
        if let type = String(describing: self).components(separatedBy: ".").last {
            return type
        }else{
            return ""
        }
    }
    
    public func primaryKeys() -> [String] {
        return []
    }
    
    public func autofillColumns() -> [String] {
        return primaryKeys()
    }
    
    public func toJSON() -> String {
        let logger = LoggerFactory.get(category: "DB", subCategory: "ModelFactory:DatabaseRecord")
        
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(self)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            return json ?? "{}"
        }catch{
            logger.log(.error, "Unable to convert to JSON", error)
            return "{}"
        }
    }
}
