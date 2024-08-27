//
//  PostgresSchemaInfo.swift
//
//  Created by Kelvin Wong on 2020/4/19.
//  Copyright © 2020 nonamecat. All rights reserved.
//

import Foundation
import LoggerFactory

public enum DatabaseType {
    case int
    case double
    case string
    case date
    case unknown
}

public class TableInfo {
    
    var name: String = ""
    var columns:[PostgresColumnInfo] = []
    var columnsMap:[String:PostgresColumnInfo] = [:]
    
    
    public init(_ name:String) {
        self.name = name
    }
    
    public func add(column:PostgresColumnInfo) {
        self.columns.append(column)
    }
    
    public func columnNames() -> [String] {
        var names:[String] = []
        for column in columns {
            names.append(column.column_name)
        }
        return names
    }
    
    public func columnTypes() -> [DatabaseType] {
        var types:[DatabaseType] = []
        for column in columns {
            types.append(column.type())
        }
        return types
    }
    
    public func mapColumns() {
        self.columnsMap.removeAll()
        for col in columns {
            self.columnsMap[col.column_name] = col
        }
    }
    
    private var loadedPrimaryKey = false
    private var loadedAutofillColumns = false
    private var primaryKey:[String] = []
    private var autofillColumns:[String] = []
    
    public func collectKeyInfo() {
        self.primaryKey = self.findPrimaryKey()
        self.autofillColumns = self.findAutoFillColumns()
    }
    
    public func getPrimaryKey() -> [String] {
        if !loadedPrimaryKey || !loadedAutofillColumns {
            self.collectKeyInfo()
        }
        return self.primaryKey
    }
    
    public func getAutofillColumns() -> [String] {
        if !loadedPrimaryKey || !loadedAutofillColumns {
            self.collectKeyInfo()
        }
        return self.autofillColumns
    }
    
    private func findPrimaryKey() -> [String] {
        var result:[String] = []
        for col in columns {
            if col.isSerial() {
                result.append(col.column_name)
            }
        }
        return result
    }
    
    private func findAutoFillColumns() -> [String] {
        var result:[String] = []
        for col in columns {
            if col.useNextval() {
                result.append(col.column_name)
            }
        }
        return result
    }
    
    
}

public class PostgresColumnInfo : Codable & EncodableDBRecord {
    
    var column_name:String = ""
    var data_type:String = ""
    var is_nullable:String = ""
    var is_identity:String = ""
    var character_maximum_length:Int? = nil
    var numeric_precision:Int? = nil
    var numeric_precision_radix:Int? = nil
    var ordinal_position:Int = 0
    var column_default:String? = nil
    var udt_name:String = ""
    
    public init() {
        
    }
    
    public func isNullable() -> Bool {
        return is_nullable == "YES"
    }
    
    public func isIdentity() -> Bool {
        return is_identity == "YES"
    }
    
    public func useNextval() -> Bool {
        if let defaul_value = column_default {
            return defaul_value.hasPrefix("nextval('\"") && defaul_value.hasSuffix("\"'::regclass)")
        }else{
            return false
        }
    }
    
    public func isSerial() -> Bool {
        return udt_name == "int4" && useNextval()
    }
    
    public func hasDefaultValue() -> Bool {
        return column_default != nil
    }
    
    public func type() -> DatabaseType {
        if data_type == "integer" {
            return .int
        }
        if data_type == "character varying" {
            return .string
        }
        if data_type == "date" {
            return .date
        }
        if data_type == "real" {
            return .double
        }
        return .unknown
    }
    
    public func toJSON() -> String {
        let logger = LoggerFactory.get(category: "DB", subCategory: "ModelFactory:PostgresSchemaInfo")
        
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
