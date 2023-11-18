//
//  DependencyContainerTests.swift
//
//
//  Created by kelvinwong on 2023/11/18.
//

import XCTest
import LoggerFactory
@testable import PostgresModelFactory

protocol IService {
    func hello() -> String
}

final class DependencyContainerTests: XCTestCase {
    
    override func setUp() async throws {
        print()
        print("==== \(self.description) ====")
        
        LoggerFactory.append(logWriter: ConsoleLogger())
        LoggerFactory.enable([.info, .warning, .error, .trace])
    }
    
    func testDependency() throws {
        
        final class OneService : IService {
            
            func hello() -> String {
                return "hello"
            }
        }

        final class TwoService : IService {
            
            func hello() -> String {
                return "morning"
            }
        }
        
        final class ParentService {
            
            @Autowired private var childService : IService
            @Autowired(name: "one") private var oneService : IService
            
            init() {}
            
            public func sayHello() {
                XCTAssertNotNil(self.childService)
                let word = self.childService.hello()
                print(word)
                XCTAssertEqual("morning", word)
            }
            
            public func askOne() {
                XCTAssertNotNil(self.oneService)
                let word = self.oneService.hello()
                print(word)
                XCTAssertEqual("hello", word)
            }
        }
        
        ServiceContainer.register(type: IService.self, TwoService())
        
        ServiceContainer.register(name: "one", type: IService.self, OneService())
        
        let parent = ParentService()
        parent.sayHello()
        parent.askOne()
        
        let child = ServiceContainer.resolve(name:"one", IService.self)
        XCTAssertNotNil(child)
        print(child?.hello())
        
        
    }
    
}
