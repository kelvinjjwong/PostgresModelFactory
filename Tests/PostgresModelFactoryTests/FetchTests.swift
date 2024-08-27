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
        
        print("======== setup profile ===========")
        
        // profile
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "postgres"
        databaseProfile.database = "postgres"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        let db = Database.init(profile: databaseProfile)
        
        print("======== create schema ===========")
        
        // create schema
        let migrator = DatabaseVersionMigrator(db).dropBeforeCreate(true).cleanVersions(true)
        
        migrator.version("v1") { db in
            try db.create(table: "Image", body: { t in
                t.column("id", .serial).primaryKey().unique().notNull()
                t.column("photoDate", .date)
                t.column("photoDateTime", .datetime)
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
        
        print("======== query table info ===========")
        
        // query table info
        XCTAssertNoThrow(try db.queryTableInfos(schema: "public"))
        
        let tables = try db.queryTableInfos(schema: "public")
        XCTAssertNotEqual(0, tables.count)
        
        for table in tables {
            XCTAssertNotEqual(0, table.columns.count)
            
            print(">>>>>>>> table: \(table.name) <<<<<<<<<<")
            
            for column in table.columns {
                print(column.toJSON())
            }
        }
        
        print("======== add new record ===========")
        
        // add new record
        final class Image : DatabaseRecord {
            var id = 0
            var photoYear:Int = 2024
            var photoMonth:Int = 8
            var photoDate:Date = Date()
            var photoDateTime:Date = Date()
            var owner:String = "me"
        }
        
        do {
            let record = Image()
            try record.save(db)
            
            let rec2 = Image()
            rec2.photoDate = Date().adding(.day, value: 1)
            rec2.photoDateTime = Date().adding(.day, value: 1)
            try rec2.save(db)
            
            let rec3 = Image()
            rec3.photoDate = Date().adding(.day, value: -1)
            rec3.photoDateTime = Date().adding(.day, value: -1)
            try rec3.save(db)
            
        }catch {
            logger.log(.error, error)
        }
        
        print("======== query record ===========")
        // query record
        do {
            let records = try Image.fetchAll(db)
            for r in records {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
            }
        }catch {
            logger.log(.error, error)
        }
        
        print("======== query record by primary key ===========")
        // query record
        do {
            if let r = try Image.fetchOne(db, parameters: ["id": 2]) {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
            }
        }catch {
            logger.log(.error, error)
        }
        print("======== query record with parameter date specified timezone ===========")
        // query record with custom parameter
        do {
            let records = try Image.fetchAll(db, parameters: ["photoDate": Date().postgresDate(in: .current)])
            for r in records {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
            }
        }catch {
            logger.log(.error, error)
        }
        print("======== query record with parameter date ===========")
        // query record with custom parameter
        do {
            let records = try Image.fetchAll(db, parameters: ["photoDate": Date()])
            for r in records {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
            }
        }catch {
            logger.log(.error, error)
        }
        
        
    }
    
}
