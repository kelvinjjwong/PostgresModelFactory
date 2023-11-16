//
//  VersionMigrationTests.swift
//
//
//  Created by Kelvin Wong on 2023/11/15.
//


import XCTest
import LoggerFactory
@testable import PostgresModelFactory

final class VersionMigrationTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
        
        LoggerFactory.append(logWriter: ConsoleLogger())
        LoggerFactory.enable([.info, .warning, .error, .trace])
    }
    
    func testInitializeVersionTable() throws {
        
        let logger = LoggerFactory.get(category: "DB", subCategory: "testInitializeVersionTable")
        
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
        
        // verify
        
        final class Image : DatabaseRecord {
            
            var id = 0
            var photoDate:Date?
            var photoYear = 0
            var photoMonth = 0
            var owner = ""
            
            public init() {}
            
            public func primaryKeys() -> [String] {
                return ["id"]
            }
        }
        
        // insert
        
        let record = Image()
        record.photoDate = Date()
        record.photoYear = 2023
        record.photoMonth = 11
        record.owner = "me"
        
        do{
            try record.save(db)
        }catch{
            logger.log(.error, error)
        }
        
        // count
        XCTAssertNoThrow(try Image.count(db))
        do {
            let i = try Image.count(db)
            XCTAssertEqual(1, i)
        }catch {
            logger.log(.error, error)
        }
        
        // insert
        
        let record2 = Image()
        record2.photoDate = Date()
        record2.photoYear = 2025
        record2.photoMonth = 8
        record2.owner = "you"
        
        do{
            try record2.save(db)
        }catch{
            logger.log(.error, error)
        }
        
        // count
        XCTAssertNoThrow(try Image.count(db))
        do {
            let i = try Image.count(db)
            XCTAssertEqual(2, i)
        }catch {
            logger.log(.error, error)
        }
        
        // query
        
        do {
            if let findRecord = try Image.fetchOne(db, parameters: ["owner": "you"]) {
                XCTAssertNotNil(findRecord)
                logger.log("found record: \(findRecord.toJSON())")
                
                XCTAssertEqual(8, findRecord.photoMonth)
                XCTAssertEqual("you", findRecord.owner)
                XCTAssertNotEqual(0, findRecord.id)
                
                // update
                findRecord.photoMonth = 5
                
                do{
                    try findRecord.save(db)
                }catch{
                    logger.log(.error, error)
                }
                
                if let findAgain = try Image.fetchOne(db, parameters: ["owner": "you"]) {
                    XCTAssertNotNil(findAgain)
                    logger.log("found record: \(findAgain.toJSON())")
                    
                    XCTAssertEqual(5, findAgain.photoMonth)
                    XCTAssertEqual("you", findAgain.owner)
                    XCTAssertEqual(findRecord.id, findAgain.id)
                    
                    // delete
                    
                    XCTAssertNoThrow(try findAgain.delete(db))
                    
                    let shouldDeleted = try Image.fetchOne(db, parameters: ["owner": "you"])
                    
                    XCTAssertNil(shouldDeleted)
                    
                    let j = try Image.count(db)
                    
                    XCTAssertEqual(1, j)
                }
                
            }else{
                logger.log("not found")
            }
        }catch{
            logger.log(.error, error)
        }
        
        
    }
}
