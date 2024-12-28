//
//  Database+Postgres.swift
//
//  Created by Kelvin Wong on 2020/4/20.
//  Copyright © 2020 nonamecat. All rights reserved.
//

import Foundation
import LoggerFactory

public class PostgresDB : DatabaseInterface {
    
    
    fileprivate let logger = LoggerFactory.get(category: "DB", subCategory: "PostgresDB")
    
    private var databaseProfile:DatabaseProfile
    private var impl:DatabaseImplInterface
    
    private var tables:[String:TableInfo] = [:]
    
    public init(databaseProfile: DatabaseProfile) {
        self.databaseProfile = databaseProfile
        
        let _ = self.logger.loggingCategory(category: "DB", subCategory: "\(databaseProfile.engine):\(databaseProfile.host):\(databaseProfile.database):\(databaseProfile.schema)")
        
        if databaseProfile.engine == "PostgreSQL" {
            self.impl = DatabaseImplPostgresClientKit(databaseProfile: databaseProfile)
        }else{
            fatalError("Unsupported engine [\(databaseProfile.engine)]")
        }
        self.schemaSqlGenerator = PostgresSchemaSQLGenerator()
    }
    
    public func mappedTableInfo(table: String) -> TableInfo? {
        return self.mappedTableInfo(table: table, schema: "public")
    }
    
    public func mappedTableInfo(table:String, schema:String) -> TableInfo? {
        if let info = self.tables[table] {
            return info
        }else{
            do {
                let info = try self.queryTableInfo(table: table, schema: schema)
                self.tables[table] = info
                return info
            }catch{
                self.logger.log(.error, error)
                return nil
            }
        }
    }
    
    private let schemaSqlGenerator:SchemaSQLGenerator
    
    public func getSchemaSQLGenerator() -> SchemaSQLGenerator {
        return self.schemaSqlGenerator
    }
    
    public func connect() throws {
        do {
            try self.impl.connect()
        } catch {
            self.logger.log(.error, "[connect] Error at PostgresDB.connect()", error)
            throw error
        }
    }
    
    public func version() throws -> String {
        final class TempRecord : DatabaseRecord {
            var ver:String = ""
            public init() {}
        }
        
        var records:[TempRecord] = []
        do {
            records = try TempRecord.fetchAll(self, sql: "select version() as ver")
        }catch{
            self.logger.log(.error, error)
            return error.localizedDescription
        }
        if records.count == 1 {
            return records[0].ver
        }
        return ""
    }
    
    public func execute(sql: String) throws {
        self.logger.log(.trace, "[execute] >>> execute sql: \(sql)")
        let statement = SQLStatement(sql: sql)
        try self.impl.execute(statement: statement)
    }
    
    public func execute(sql: String, parameterValues:[DatabaseValueConvertible?]) throws {
        self.logger.log(.trace, "[execute] >>> execute sql: \(sql) , parameters: \(parameterValues)")
        let statement = SQLStatement(sql: sql)
        statement.arguments = parameterValues
        try self.impl.execute(statement: statement)
    }
    
    public func delete<T:Codable & EncodableDBRecord>(object:T, table:String, primaryKeys:[String]) throws {
        var _sql = ""
        do {
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.deleteStatement(keyColumns: primaryKeys)
            _sql = statement.sql
            self.logger.log(.trace, "[delete] >>> execute sql: \(_sql)")
            try self.impl.execute(statement: statement)
        }catch{
            self.logger.log(.error, "[delete] Error at PostgresDB.delete(object:table:primaryKeys)")
            self.logger.log(.error, "[delete] Error at sql: \(_sql)", error)
            throw error
        }
    }
    
    public func save<T:Codable & EncodableDBRecord>(object:T, table:String, primaryKeys:[String], autofillColumns:[String]) throws {
        do {
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let existsStatement = generator.existsStatement(keyColumns: primaryKeys)
            self.logger.log(.trace, "[save][ifexists] >>> execute sql: \(existsStatement.sql) , parameters: \(existsStatement.arguments)")
            
            let exists = try self.impl.queryExist(existsStatement: existsStatement)
            
            if exists {
            
                let statement = generator.updateStatement(keyColumns: primaryKeys, autofillColumns: autofillColumns)
                self.logger.log(.trace, "[save][update] >>> execute sql: \(statement.sql) , parameters: \(statement.arguments)")
                
                try self.impl.execute(statement: statement)
            } else {
                let statement = generator.insertStatement(autofillColumns: autofillColumns)
                self.logger.log(.trace, "[save][insert] >>> execute sql: \(statement.sql) , parameters: \(statement.arguments)")
                
                try self.impl.execute(statement: statement)
            }

        } catch {
            self.logger.log(.error, "[save] Error at PostgresDB.save(object:table:primaryKeys)", error)
            throw error
        }
        
    }
    
    public func query<T:Codable & EncodableDBRecord>(object:T, table:String, sql:String, values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [T] {
        
        var _sql = ""
        do {
            
            let _ = SQLStatementGenerator(table: table, record: object)
//            let columnNames = generator.persistenceContainer.columns
            
            var pagination = ""
            if let offset = offset, let limit = limit {
                pagination = "OFFSET \(offset) LIMIT \(limit)"
                
            }
            _sql = "\(sql) \(pagination)"
            
            self.logger.log(.trace, "[query] >>> query sql: \(_sql) , parameters: \(values)")
            
            return try self.impl.query(object: object, table: table, sql: _sql, values: values)
        } catch {
            self.logger.log(.error, "[query] Error at PostgresDB.query(object:table:sql:values:offset:limit) -> [T]")
            self.logger.log(.error, "[query] Error at sql: \(_sql) , parameters: \(values)", error)
            throw error
        }
    }
    
    public func query<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, orderBy:String = "", values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [T] {
        var _sql = ""
        do {
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.selectStatement(where: whereSQL, orderBy: orderBy, values: values, schema: self.databaseProfile.schema)
//            let columnNames = generator.persistenceContainer.columns
            
            var pagination = ""
            if let offset = offset, let limit = limit {
                pagination = "OFFSET \(offset) LIMIT \(limit)"
                
            }
            
            _sql = "\(statement.sql) \(pagination)"
            
            self.logger.log(.trace, "[query] >>> query sql: \(_sql) , parameters: \(values)")
            
            return try self.impl.query(object: object, table: table, sql: _sql, values: values)
        } catch {
            self.logger.log(.error, "[query] Error at PostgresDB.query(object:table:where:orderBy:values:offset:limit) -> [T]")
            self.logger.log(.error, "[query] Error at sql: \(_sql) , parameters: \(values)", error)
            throw error
        }
    }
    
    public func query<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?] = [:], orderBy:String = "") throws -> [T] {
        var _sql = ""
        do {
            
            let keyColumns:[String] = Array(parameters.keys)
            let values:[DatabaseValueConvertible?] = Array(parameters.values)
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let columnNames = generator.persistenceContainer.columns
            let joinedColumnNames = columnNames.joinedQuoted(separator: ",")
            let statement = generator.selectStatement(columns: joinedColumnNames, keyColumns: keyColumns, orderBy: orderBy, schema: self.databaseProfile.schema)
            
            _sql = statement.sql
            
            self.logger.log(.trace, "[query] >>> query sql: \(_sql) , parameters: \(values)")
            
            return try self.impl.query(object: object, table: table, sql: _sql, values: values)
        } catch {
            self.logger.log(.error, "[query] Error at PostgresDB.query(object:table:parameters:orderBy) -> [T]")
            self.logger.log(.error, "[query] Error at sql: \(_sql) , parameters: \(Array(parameters.values))", error)
            throw error
        }
    }
    
    public func queryOne<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, orderBy:String = "", values:[DatabaseValueConvertible?] = []) throws -> T? {
        let list = try self.query(object: object, table: table, where: whereSQL, orderBy: orderBy, values: values)
        if list.count > 0 {
            return list[0]
        }else{
            return nil
        }
    }
    
    public func queryOne<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?] = [:]) throws -> T? {
        let list = try self.query(object: object, table: table, parameters: parameters)
        if list.count > 0 {
            return list[0]
        }else{
            return nil
        }
    }
    
    public func queryOne<T:Codable & EncodableDBRecord>(object:T, table:String, sql:String, values:[DatabaseValueConvertible?] = []) throws -> T? {
        let list = try self.query(object: object, table: table, sql: sql, values: values)
        if list.count > 0 {
            return list[0]
        }else{
            return nil
        }
    }
    
    public func count(sql:String) throws -> Int {
        return try self.count(sql: sql, parameterValues: [])
    }
    
    public func count(sql:String, parameterValues: [DatabaseValueConvertible?]) throws -> Int {
        self.logger.log(.trace, "[count] >>> count sql: \(sql) , parameters: \(parameterValues)")
        do {
            return try self.impl.count(sql: sql, parameterValues: parameterValues)
        } catch {
            self.logger.log(.error, "[count] Error at PostgresDB.count(sql:parameterValues)")
            self.logger.log(.error, "[count] Error sql: \(sql) , parameters: \(parameterValues)", error)
//            self.logger.log(error) // better error handling goes here
            throw error
        }
    }
    
    public func count<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?] = [:]) throws -> Int {
        var _sql = ""
        do {
            
            let keyColumns:[String] = Array(parameters.keys)
            let values:[DatabaseValueConvertible?] = Array(parameters.values)
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.countStatement(keyColumns: keyColumns)
            //let columnNames = generator.persistenceContainer.columns
            
            _sql = statement.sql
            self.logger.log(.trace, "[count] >>> count sql: \(_sql) , parameters: \(values)")
            
            return try self.impl.count(sql: _sql, parameterValues: values)
        } catch {
            self.logger.log(.error, "[count] Error at PostgresDB.count(object:table:parameters)")
            self.logger.log(.error, "[count] Error at sql: \(_sql) , parameters: \(Array(parameters.values))", error)
//            self.logger.log(error) // better error handling goes here
            throw error
        }
    }
    
    public func count<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, values:[DatabaseValueConvertible?] = []) throws -> Int {
        var _sql = ""
        do {
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.countStatement(where: whereSQL, values: values)
            //let columnNames = generator.persistenceContainer.columns
            
            _sql = statement.sql
            self.logger.log(.trace, "[count] >>> count sql: \(_sql) , parameters: \(values)")
            
            return try self.impl.count(sql: _sql, parameterValues: values)
        } catch {
            self.logger.log(.error, "[count] Error at PostgresDB.count(object:table:where:values)")
            self.logger.log(.error, "[count] Error at sql: \(_sql) , parameters: \(values)", error)
//            self.logger.log(error) // better error handling goes here
            throw error
        }
    }
    
    public func queryTableInfo(table:String) throws -> TableInfo {
        return try self.queryTableInfo(table: table, schema: "public")
    }
    
    public func queryTableInfo(table:String, schema:String) throws -> TableInfo {
        do {
            
            let generator = SQLStatementGenerator(table: "columns", record: PostgresColumnInfo())
            let statement = generator.selectStatement(columns: "column_name,data_type,is_nullable,is_identity,character_maximum_length,numeric_precision,numeric_precision_radix,ordinal_position,column_default,udt_name",
                                                      keyColumns: ["table_schema", "table_name"],
                                                      orderBy: "ordinal_position",
                                                      schema: "information_schema")
            let _ = generator.persistenceContainer.columns
            
            let tableInfo = TableInfo(table)
            let columnInfos = try self.impl.query(object: PostgresColumnInfo(), table: "information_schema", sql: statement.sql, values: [schema, table])
            tableInfo.columns = columnInfos
            tableInfo.mapColumns()
            
            return tableInfo
        } catch {
            self.logger.log(.error, "Error at PostgresDB.queryTableInfo", error)
//            self.logger.log(error) // better error handling goes here
            throw error
        }
    }
    
    
    public func queryTableInfos(schema:String = "public") throws -> [TableInfo] {
        var tables:[TableInfo] =  []
        do {
            let sql = "SELECT table_name FROM information_schema.tables WHERE table_schema=$1"
            
            final class Tableinfo : DatabaseRecord {
                var table_name:String = ""
            }
            
            let tableinfos = try self.impl.query(object: Tableinfo(), table: "tables", sql: sql, values: [schema])
            
            for table in tableinfos {
                let generator = SQLStatementGenerator(table: "columns", record: PostgresColumnInfo())
                let statement = generator.selectStatement(columns: "column_name,data_type,is_nullable,is_identity,character_maximum_length,numeric_precision,numeric_precision_radix,ordinal_position,column_default,udt_name",
                                                          keyColumns: ["table_schema", "table_name"],
                                                          orderBy: "ordinal_position",
                                                          schema: "information_schema")
                
                let tableInfo = TableInfo(table.table_name)
                
                let columnInfos = try self.impl.query(object: PostgresColumnInfo(), table: "tables", sql: statement.sql, values: [schema, table.table_name])
                
                tableInfo.columns = columnInfos
                tableInfo.mapColumns()
                tables.append(tableInfo)
                
            }
            
        } catch {
            self.logger.log(.error, error) // better error handling goes here
            throw error
        }
        return tables
    }
}

extension PostgresDB : LoggerUser {
    
    public func loggingCategory(category: String, subCategory: String) -> Self {
        let _ = self.logger.loggingCategory(category: category, subCategory: subCategory)
        return self
    }
    
    public func loggingDestinations(_ destinations: [String]) -> Self {
        let _ = self.logger.loggingDestinations(destinations)
        return self
    }
    
    public func excludeLoggingLevels(_ levels: [LogType]) -> Self {
        let _ = self.logger.excludeLoggingLevels(levels)
        return self
    }
    
    public func includeLoggingLevels(_ levels: [LogType]) -> Self {
        let _ = self.logger.includeLoggingLevels(levels)
        return self
    }
}
