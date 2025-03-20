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
                t.column("tags", .json)
                t.column("tagb", .jsonb)
                t.column("tagx", .text_array)
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
            var photoYear = 0
            var photoMonth = 0
            var photoDate:Date?
            var photoDateTime:Date?
            var owner = ""
            var tags:String? = nil
            var tagb:String? = nil
            var tagx:String? = nil
            
            func primaryKeys() -> [String] {
                return ["id"]
            }
        }
        
        do {
            let record = Image()
            record.photoYear = 1999
            record.photoMonth = 2
            record.owner = "me"
            record.tags = """
{"sex":"female"}
"""
            record.tagb = """
{"sex":"male"}
"""
            try record.save(db)
            
            let rec1 = Image()
            rec1.photoDate = Date()
            rec1.photoDateTime = Date()
            rec1.photoYear = 2024
            rec1.photoMonth = 8
            rec1.owner = "he"
            try rec1.save(db)
            
            let rec2 = Image()
            rec2.photoDate = Date().adding(.day, value: 1)
            rec2.photoDateTime = Date().adding(.day, value: 1)
            rec2.photoYear = 2022
            rec2.photoMonth = 6
            rec2.owner = "you"
            try rec2.save(db)
            
            let rec3 = Image()
            rec3.photoDate = Date().adding(.day, value: -1)
            rec3.photoDateTime = Date().adding(.day, value: -1)
            rec3.photoYear = 2033
            rec3.photoMonth = 12
            rec3.owner = "she"
            try rec3.save(db)
            
            let rec4 = Image()
            rec4.photoDate = Date().adding(.day, value: -99)
            rec4.photoDateTime = Date().adding(.day, value: -99)
            try rec4.save(db)
            
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
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
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
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
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
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
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
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
            }
        }catch {
            logger.log(.error, error)
        }
        print("======== query record with sql ===========")
        // query record with custom parameter
        final class TempRecord:DatabaseRecord {
            var photoMonth: Int? = 0
            public init() {}
        }
        do {
            if let r = try TempRecord.fetchOne(db, sql: "select distinct max(\"photoMonth\") \"photoMonth\" from \"Image\"") {
                print(r.photoMonth)
            }
        }catch {
            logger.log(.error, error)
        }
        print("======== query record with json field ===========")
        // query record with custom parameter
        do {
            let records = try Image.fetchAll(db, sql: """
select * from "Image" where ("tags"->>'sex') = 'female'
""")
            for r in records {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
            }
        }catch {
            logger.log(.error, error)
        }
        print("======== query record with jsonb field ===========")
        // query record with custom parameter
        do {
            let records = try Image.fetchAll(db, sql: """
select * from "Image" where ("tagb"->>'sex') = 'male'
""")
            for r in records {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
            }
        }catch {
            logger.log(.error, error)
        }
        print("======== update record with jsonb field ===========")
        // query record with custom parameter
        do {
            try db.execute(sql: """
update "Image" set "tagb" = jsonb_set("tagb", array['is_default'], to_jsonb(false)) where ("tagb"->>'sex') = 'male'
""")
            let records = try Image.fetchAll(db, sql: """
select * from "Image" where ("tagb"->>'sex') = 'male'
""")
            for r in records {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
            }
        }catch {
            logger.log(.error, error)
        }
        print("======== update record with text array field (unique) ===========")
        // query record with custom parameter
        do {
            try db.execute(sql: """
update "Image" set "tagx" = ARRAY(SELECT DISTINCT UNNEST("tagx" || '{a,b,c}')) where "owner" = 'me'
""")
            try db.execute(sql: """
update "Image" set "tagx" = ARRAY(SELECT DISTINCT UNNEST("tagx" || '{a,d,f}')) where "owner" = 'me'
""")
            try db.execute(sql: """
update "Image" set "tagx" = ARRAY(SELECT DISTINCT UNNEST("tagx" || '{z,x,f}')) where "owner" = 'me'
""")
            let records = try Image.fetchAll(db, sql: """
select * from "Image" where "owner" = 'me'
""")
            for r in records {
                print(r.id)
                print(r.photoDate)
                print(r.photoDateTime)
                print(r.owner)
                print(r.tags)
                print(r.tagb)
                print(r.tagx)
            }
        }catch {
            logger.log(.error, error)
        }
        
        
    }
    
}
