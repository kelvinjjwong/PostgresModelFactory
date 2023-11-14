//
//  ConnectivityTests.swift
//
//
//  Created by kelvinwong on 2023/11/12.
//


import XCTest
import LoggerFactory
@testable import PostgresModelFactory

final class ConnectivityTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
        
        LoggerFactory.append(logWriter: ConsoleLogger())
        LoggerFactory.enable([.info, .warning, .error, .trace])
    }
    
    func testConnectSuccess() throws {
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "postgres"
        databaseProfile.database = "postgres"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        XCTAssertNoThrow(try Database(profile: databaseProfile).connect())
    }
    
    func testConnectFail() throws {
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "nosuchuser"
        databaseProfile.database = "postgres"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        XCTAssertThrowsError(try Database(profile: databaseProfile).connect())
    }
}
