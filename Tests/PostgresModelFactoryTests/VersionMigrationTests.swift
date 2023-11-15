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
        
        do {
            if let findRecord = try Image.fetchOne(db) {
                logger.log("found record id: \(findRecord.id)")
                logger.log(findRecord.toJSON())
            }
        }catch{
            logger.log(.error, error)
        }
    }
}
