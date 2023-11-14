//
//  DatabaseProfileJSONifyTests.swift
//  
//
//  Created by kelvinwong on 2023/11/12.
//

import XCTest
@testable import PostgresModelFactory

final class DatabaseProfileJSONifyTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
    }
    
    func testToJson() throws {
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "postgres"
        databaseProfile.database = "postgres"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        let json = databaseProfile.toJSON()
        print(json)
        XCTAssertNotNil(json)
    }
    
    func testFromJson() throws {
        let jsonString = """
{"port":5432,"password":"","schema":"public","selected":false,"nopsw":true,"ssl":false,"database":"postgres","user":"postgres","engine":"PostgreSQL","host":"localhost"}
"""
        let json = DatabaseProfile.fromJSON(jsonString)
        XCTAssertNotNil(json)
        if let json = json {
            print(json)
            XCTAssertEqual(5432, json.port)
            XCTAssertEqual("", json.password)
            XCTAssertEqual("public", json.schema)
            XCTAssertEqual(false, json.selected)
            XCTAssertEqual(true, json.nopsw)
            XCTAssertEqual(false, json.ssl)
            XCTAssertEqual("postgres", json.database)
            XCTAssertEqual("postgres", json.user)
            XCTAssertEqual("PostgreSQL", json.engine)
            XCTAssertEqual("localhost", json.host)
        }
    }
}
