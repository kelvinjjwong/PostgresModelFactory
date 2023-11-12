//
//  File.swift
//  
//
//  Created by kelvinwong on 2023/11/12.
//

import XCTest
@testable import PostgresModelFactory

final class FetchTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
    }
    
    func testGetLatestVersion() throws {
        
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "kelvinwong"
        databaseProfile.database = "ImageDocker"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        final class Version : CustomQueryRecord {
            var ver:Int = 0
            public init() {}
        }
        
        var err:Error?
        do {
            let version = try Version.fetchOne(Database(profile: databaseProfile),
                                                  sql: "select substring(ver, '\\d+')::int versions from version_migrations order by versions desc")
                
            print("version is \(version?.ver ?? Int.min)")
            XCTAssertNotNil(version)
            
        }catch{
            err = error
            print(error)
        }
        XCTAssertNil(err)
    }
    
    func testGetOneVersion() throws {
        
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "kelvinwong"
        databaseProfile.database = "ImageDocker"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        final class Version : CustomQueryRecord {
            var ver:String? = nil
            public init() {}
        }
        
        var err:Error?
        do {
            let version = try Version.fetchOne(Database(profile: databaseProfile),
                                                  sql: "select ver from version_migrations where ver = $1 ", values: ["v1"])
            XCTAssertNotNil(version)
            XCTAssertEqual("v1", version?.ver)
            print("version is \(version?.ver ?? "nil")")
        }catch{
            err = error
            print(error)
        }
        XCTAssertNil(err)
    }
}
