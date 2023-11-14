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
        
        let databaseProfile = DatabaseProfile()
        databaseProfile.engine = "PostgreSQL"
        databaseProfile.host = "localhost"
        databaseProfile.port = 5432
        databaseProfile.user = "postgres"
        databaseProfile.database = "postgres"
        databaseProfile.schema = "public"
        databaseProfile.nopsw = true
        
        // todo
    }
}
