//
//  Database+Postgres+PostgresClientKit.swift
//
//
//  Created by kelvinwong on 2023/11/16.
//

import Foundation
import LoggerFactory
import PostgresClientKit

public class DatabaseImplPostgresClientKit : DatabaseImplInterface {
    
    fileprivate let logger = LoggerFactory.get(category: "DB", subCategory: "PostgresDB:PostgresClientKit")
    
    private let postgresConfig: ConnectionConfiguration
    
    private var databaseProfile:DatabaseProfile
    
    public init(databaseProfile:DatabaseProfile) {
        
        self.databaseProfile = databaseProfile
        
        let _ = self.logger.loggingCategory(category: "DB", subCategory: "\(databaseProfile.engine):\(databaseProfile.host):\(databaseProfile.database):\(databaseProfile.schema)")
        
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
        configuration.socketTimeout = databaseProfile.socketTimeoutInSeconds
        self.postgresConfig = configuration
    }
    
    public func connect() throws {
        let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
        self.logger.log(.trace, "[connect] Database connected.")
        do { connection.close() }
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
    
    public func queryExist(existsStatement:SQLStatement) throws -> Bool {
        let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
        defer { connection.close() }
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
        return exists
    }
    
    public func query<T:Codable & EncodableDBRecord>(object:T, table:String, sql:String, values:[DatabaseValueConvertible?]) throws -> [T] {
        let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
        defer { connection.close() }
        
        let stmt = try connection.prepareStatement(text: "\(sql)")
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
    }
    
    public func count(sql:String, parameterValues: [DatabaseValueConvertible?]) throws -> Int {
        let connection = try PostgresClientKit.Connection(configuration: self.postgresConfig)
        defer { connection.close() }
        
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
    }
}
