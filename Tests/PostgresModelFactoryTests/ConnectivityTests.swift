import XCTest
@testable import PostgresModelFactory

final class ConnectivityTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
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
