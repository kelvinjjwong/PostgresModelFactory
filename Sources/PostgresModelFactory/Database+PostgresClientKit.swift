//
//  PostgresSQLStatementExecutor.swift
//  TreeView
//
//  Created by Kelvin Wong on 2020/4/20.
//  Copyright © 2020 nonamecat. All rights reserved.
//

import Foundation
import LoggerFactory
import PostgresClientKit


public class PostgresDB : DatabaseInterface {
    
    
    fileprivate let logger = LoggerFactory.get(category: "DB", subCategory: "PostgresDB", includeTypes: [])
    
    private let postgresConfig: ConnectionConfiguration
    
    public var schema:String = "public"
    
    private var databaseProfile:DatabaseProfile
    
    public init(databaseProfile: DatabaseProfile) {
        self.databaseProfile = databaseProfile
        
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = databaseProfile.host
        configuration.port = databaseProfile.port
        configuration.database = databaseProfile.database
        configuration.user = databaseProfile.user
        if !databaseProfile.nopsw {
            configuration.credential = .cleartextPassword(password: databaseProfile.password)
        }else{
            configuration.credential = .trust
        }
        configuration.ssl = databaseProfile.ssl
        self.postgresConfig = configuration
    }
    
    public func execute(sql: String) throws {
        self.logger.log(.trace, " >>> execute sql: \(sql)")
        let statement = SQLStatement(sql: sql)
        try self.execute(statement: statement)
    }
    
    public func execute(sql: String, parameterValues:[DatabaseValueConvertible?]) throws {
        self.logger.log(.trace, " >>> execute sql: \(sql)")
        let statement = SQLStatement(sql: sql)
        statement.arguments = parameterValues
        try self.execute(statement: statement)
    }
    
    public func execute(statement: SQLStatement) throws {

        let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
        defer { connection.close() }
        
        let stmt = try connection.prepareStatement(text: statement.sql)
        defer { stmt.close() }
        
        if statement.arguments.count > 0 {
            let _ = try stmt.execute(parameterValues: statement.arguments)
        }else{
            let _ = try stmt.execute()
        }
    }
    
    public func delete<T:Codable & EncodableDBRecord>(object:T, table:String, primaryKeys:[String]) throws {
        var _sql = ""
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.deleteStatement(keyColumns: primaryKeys)
            _sql = statement.sql
            self.logger.log(.trace, " >>> execute sql: \(_sql)")
            try self.execute(statement: statement)
        }catch{
            self.logger.log(.error, "Error at PostgresDB.delete(object:table:primaryKeys)")
            self.logger.log(.error, "Error at sql: \(_sql)", error)
            throw error
//            self.logger.log(error)
        }
    }
    
    public func connect() throws {
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            do { connection.close() }
        } catch {
            self.logger.log(.error, "Error at PostgresDB.connect()", error)
            throw error
        }
    }
    
    public func save<T:Codable & EncodableDBRecord>(object:T, table:String, primaryKeys:[String], autofillColumns:[String]) throws {
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let existsStatement = generator.existsStatement(keyColumns: primaryKeys)
            self.logger.log(.debug, "[save][ifexists] >>> execute sql: \(existsStatement.sql) , parameters: \(existsStatement.arguments)")
            let existsStmt = try connection.prepareStatement(text: existsStatement.sql)
            defer { existsStmt.close() }
            
            let existsCursor = try existsStmt.execute(parameterValues: existsStatement.arguments)
            defer { existsCursor.close() }
            
            var exists = false
            for row in existsCursor {
                let columns = try row.get().columns
                let flag = try columns[0].int() // FIXME: should load column by name rather by initial-ordered-index
                if flag == 1 {
                    exists = true
                }
            }
            
            if exists {
            
                let statement = generator.updateStatement(keyColumns: primaryKeys, autofillColumns: autofillColumns)
                self.logger.log(.debug, "[save][update] >>> execute sql: \(statement.sql)")
                let stmt = try connection.prepareStatement(text: statement.sql)
                defer { stmt.close() }
                
                let _ = try stmt.execute(parameterValues: statement.arguments)
            } else {
                let statement = generator.insertStatement(autofillColumns: autofillColumns)
                self.logger.log(.debug, "[save][insert] >>> execute sql: \(statement.sql)")
                let stmt = try connection.prepareStatement(text: statement.sql)
                defer { stmt.close() }
                
                let _ = try stmt.execute(parameterValues: statement.arguments)
            }

        } catch {
            self.logger.log(.error, "[save] Error at PostgresDB.save(object:table:primaryKeys)", error)
            throw error
        }
        
    }
    
    public func query<T:Codable & EncodableDBRecord>(object:T, table:String, sql:String, values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [T] {
        
        var _sql = ""
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let _ = SQLStatementGenerator(table: table, record: object)
//            let columnNames = generator.persistenceContainer.columns
            
            var pagination = ""
            if let offset = offset, let limit = limit {
                pagination = "OFFSET \(offset) LIMIT \(limit)"
                
            }
            _sql = "\(sql) \(pagination)"
            
            self.logger.log(.trace, " >>> query sql: \(_sql)")
            
            let stmt = try connection.prepareStatement(text: "\(_sql)")
            defer { stmt.close() }

            let cursor = try stmt.execute(parameterValues: values)
            defer { cursor.close() }

            var result:[T] = []
            for row in cursor {
                let columns = try row.get().columns
                let row = PostgresRow.read(object, types: [], values: columns) // PostgresRow(columnNames: columnNames, values: columns)
                row.table = table
                if let obj:T = try PostgresRowDecoder().decodeIfPresent(from: row) {
                    result.append(obj)
                }
            }
            return result
        } catch {
            self.logger.log(.error, "Error at PostgresDB.query(object:table:sql:values:offset:limit) -> [T]")
            self.logger.log(.error, "Error at sql: \(_sql)", error)
//            self.logger.log(error) // better error handling goes here
//            if "\(error)".contains("Host is down") {
//
//            }
            throw error
            return []
        }
    }
    
    public func query<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, orderBy:String = "", values:[DatabaseValueConvertible?] = [], offset:Int? = nil, limit:Int? = nil) throws -> [T] {
        var _sql = ""
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.selectStatement(where: whereSQL, orderBy: orderBy, values: values, schema: self.databaseProfile.schema)
//            let columnNames = generator.persistenceContainer.columns
            
            var pagination = ""
            if let offset = offset, let limit = limit {
                pagination = "OFFSET \(offset) LIMIT \(limit)"
                
            }
            
            _sql = "\(statement.sql) \(pagination)"
            
            self.logger.log(.trace, " >>> query sql: \(_sql)")
            
            let stmt = try connection.prepareStatement(text: "\(_sql)")
            defer { stmt.close() }

            let cursor = try stmt.execute(parameterValues: values)
            defer { cursor.close() }

            var result:[T] = []
            for row in cursor {
                let columns = try row.get().columns
                let row = PostgresRow.read(object, types: [], values: columns) // PostgresRow(columnNames: columnNames, values: columns)
                row.table = table
                if let obj:T = try PostgresRowDecoder().decodeIfPresent(from: row) {
                    result.append(obj)
                }
            }
            return result
        } catch {
            self.logger.log(.error, "Error at PostgresDB.query(object:table:where:orderBy:values:offset:limit) -> [T]")
            self.logger.log(.error, "Error at sql: \(_sql)", error)
//            self.logger.log(error) // better error handling goes here
            throw error
            return []
        }
    }
    
    public func query<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?] = [:], orderBy:String = "") throws -> [T] {
        var _sql = ""
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let keyColumns:[String] = Array(parameters.keys)
            let values:[PostgresValueConvertible?] = Array(parameters.values)
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let columnNames = generator.persistenceContainer.columns
            let joinedColumnNames = columnNames.joinedQuoted(separator: ",")
            let statement = generator.selectStatement(columns: joinedColumnNames, keyColumns: keyColumns, orderBy: orderBy, schema: self.databaseProfile.schema)
            
            _sql = statement.sql
            
            self.logger.log(.trace, " >>> query sql: \(_sql)")
            
            let stmt = try connection.prepareStatement(text: _sql)
            defer { stmt.close() }

            let cursor = try stmt.execute(parameterValues: values)
            defer { cursor.close() }

            var result:[T] = []
            for row in cursor {
                let columns = try row.get().columns
                let row = PostgresRow.read(object, types: [], values: columns) //PostgresRow(columnNames: columnNames, values: columns)
                row.table = table
                if let obj:T = try PostgresRowDecoder().decodeIfPresent(from: row) {
                    result.append(obj)
                }
            }
            return result
        } catch {
            self.logger.log(.error, "Error at PostgresDB.query(object:table:parameters:orderBy) -> [T]")
            self.logger.log(.error, "Error at sql: \(_sql)", error)
//            self.logger.log(error) // better error handling goes here
            throw error
            return []
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
        self.logger.log(.trace, " >>> count sql: \(sql)")
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            //self.logger.log(">> count sql: \(sql)")
            let stmt = try connection.prepareStatement(text: sql)
            defer { stmt.close() }

            let cursor = try stmt.execute(parameterValues: parameterValues)
            defer { cursor.close() }

            var result:Int = 0
            if let next = cursor.next() {
                let columns = try next.get().columns
                result = try columns[0].int()
            }
            return result
        } catch {
            self.logger.log(.error, "Error at PostgresDB.count(sql:parameterValues)")
            self.logger.log(.error, "Error sql: \(sql)", error)
//            self.logger.log(error) // better error handling goes here
            throw error
            return -1
        }
    }
    
    public func count<T:Codable & EncodableDBRecord>(object:T, table:String, parameters:[String:DatabaseValueConvertible?] = [:]) throws -> Int {
        var _sql = ""
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let keyColumns:[String] = Array(parameters.keys)
            let values:[PostgresValueConvertible?] = Array(parameters.values)
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.countStatement(keyColumns: keyColumns)
            //let columnNames = generator.persistenceContainer.columns
            
            //self.logger.log(">> count sql: \(statement.sql)")
            let stmt = try connection.prepareStatement(text: statement.sql)
            _sql = statement.sql
            defer { stmt.close() }

            let cursor = try stmt.execute(parameterValues: values)
            defer { cursor.close() }

            var result:Int = 0
            if let next = cursor.next() {
                let columns = try next.get().columns
                result = try columns[0].int()
            }
            return result
        } catch {
            self.logger.log(.error, "Error at PostgresDB.count(object:table:parameters)")
            self.logger.log(.error, "Error at sql: \(_sql)", error)
//            self.logger.log(error) // better error handling goes here
            throw error
            return -1
        }
    }
    
    public func count<T:Codable & EncodableDBRecord>(object:T, table:String, where whereSQL:String, values:[DatabaseValueConvertible?] = []) throws -> Int {
        var _sql = ""
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let generator = SQLStatementGenerator(table: table, record: object)
            let statement = generator.countStatement(where: whereSQL, values: values)
            //let columnNames = generator.persistenceContainer.columns
            
            _sql = statement.sql
//            self.logger.log(">> count sql: \(statement.sql)")
            let stmt = try connection.prepareStatement(text: statement.sql)
            defer { stmt.close() }

            let cursor = try stmt.execute(parameterValues: values)
            defer { cursor.close() }

            var result:Int = 0
            if let next = cursor.next() {
                let columns = try next.get().columns
                result = try columns[0].int()
            }
            return result
        } catch {
            self.logger.log(.error, "Error at PostgresDB.count(object:table:where:values)")
            self.logger.log(.error, "Error at sql: \(_sql)", error)
//            self.logger.log(error) // better error handling goes here
            throw error
            return -1
        }
    }
    
    public func queryTableInfo(table:String, schema:String = "public") throws -> TableInfo {
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let generator = SQLStatementGenerator(table: "columns", record: PostgresColumnInfo())
            let statement = generator.selectStatement(columns: "column_name,data_type,is_nullable,is_identity,character_maximum_length,numeric_precision,numeric_precision_radix",
                                                      keyColumns: ["table_schema", "table_name"],
                                                      schema: "information_schema")
            let columnNames = generator.persistenceContainer.columns
            
            let stmt = try connection.prepareStatement(text: statement.sql)
            defer { stmt.close() }

            let cursor = try stmt.execute(parameterValues: [schema, table])
            defer { cursor.close() }

            
            let tableInfo = TableInfo(table)
            for row in cursor {
                let columns = try row.get().columns
                let row = PostgresRow(columnNames: columnNames, values: columns)
                row.table = table
                if let col:PostgresColumnInfo = try PostgresRowDecoder().decodeIfPresent(from: row) {
                    tableInfo.add(column: col)
                }
            }
            
            return tableInfo
        } catch {
            self.logger.log(.error, "Error at PostgresDB.queryTableInfo", error)
//            self.logger.log(error) // better error handling goes here
            throw error
            return TableInfo(table)
        }
    }
    
    
    public func queryTableInfos(schema:String = "public") throws -> [TableInfo] {
        var tables:[TableInfo] =  []
        do {
            let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
            defer { connection.close() }
            
            let stmt = try connection.prepareStatement(text: "SELECT table_name FROM information_schema.tables WHERE table_schema=$1")
            defer { stmt.close() }

            let cursorTable = try stmt.execute(parameterValues: [schema])
            defer { cursorTable.close() }

            for row in cursorTable {
                let columns = try row.get().columns
                let table = try columns[0].string()
                let tableInfo = TableInfo(table)
                tables.append(tableInfo)
            }
            
            for table in tables {
                let generator = SQLStatementGenerator(table: "columns", record: PostgresColumnInfo())
                let statement = generator.selectStatement(columns: "column_name,data_type,is_nullable,is_identity,character_maximum_length,numeric_precision,numeric_precision_radix",
                                                          keyColumns: ["table_schema", "table_name"],
                                                          schema: "information_schema")
                let columnNames = generator.persistenceContainer.columns
                
                let stmt = try connection.prepareStatement(text: statement.sql)
                defer { stmt.close() }

                let cursor = try stmt.execute(parameterValues: [schema, table.name])
                defer { cursor.close() }

                
                for row in cursor {
                    let columns = try row.get().columns
                    let row = PostgresRow(columnNames: columnNames, values: columns)
                    row.table = table.name
                    if let col:PostgresColumnInfo = try PostgresRowDecoder().decodeIfPresent(from: row) {
                        table.add(column: col)
                    }
                }
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