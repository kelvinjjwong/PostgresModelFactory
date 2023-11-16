//
//  FetchTests.swift
//  
//
//  Created by kelvinwong on 2023/11/12.
//

import XCTest
import LoggerFactory
@testable import PostgresModelFactory

final class FetchTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
        
        LoggerFactory.append(logWriter: ConsoleLogger())
        LoggerFactory.enable([.info, .warning, .error, .trace])
    }
    
    func testGetTableInfo() throws {
        
        let logger = LoggerFactory.get(category: "DB", subCategory: "testGetTableInfo")
        
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "postgres"
        databaseProfile.database = "postgres"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        let db = Database.init(profile: databaseProfile)
        
        let migrator = DatabaseVersionMigrator(db).dropBeforeCreate(true).cleanVersions(true)
        
        migrator.version("v1") { db in
            try db.create(table: "Image", body: { t in
                t.column("id", .serial).primaryKey().unique().notNull()
                t.column("photoDate", .datetime)
                t.column("photoYear", .integer).notNull().defaults(to: 0)
                t.column("photoMonth", .integer).notNull().defaults(to: 0)
                t.column("owner", .text).defaults(to: "")
            })
        }
        
        do {
            try migrator.migrate()
        }catch{
            logger.log(.error, error)
        }
        
        XCTAssertNoThrow(try db.queryTableInfos(schema: "public"))
        
        let tables = try db.queryTableInfos(schema: "public")
        XCTAssertNotEqual(0, tables.count)
        
        for table in tables {
            XCTAssertNotEqual(0, table.columns.count)
            
            for column in table.columns {
                print(column.toJSON())
            }
        }
    }
    
}
