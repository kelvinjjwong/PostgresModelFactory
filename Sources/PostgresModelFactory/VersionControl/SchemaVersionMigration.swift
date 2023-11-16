//
//  SchemaVersionMigration.swift
//
//  Created by Kelvin Wong on 2020/4/21.
//  Copyright © 2020 nonamecat. All rights reserved.
//

import Foundation
import LoggerFactory

public protocol SchemaSQLGenerator {
    
    func transform(_ definition:DatabaseTableDefinition) -> [String]
    func transform(_ definition:DatabaseTriggerDefinition) -> [String]
    func exists(version: String) -> String
    func initialise() -> String
    func cleanVersions() -> String
    func add(version: String) -> String
    func dropBeforeCreate(_ dropBeforeCreate:Bool) -> Self
}

public protocol DatabaseChangeImplement {
    
    func apply(change:DatabaseTableDefinition) throws
    func apply(change:DatabaseTriggerDefinition) throws
    func exists(version:String) throws -> Bool
    func add(version:String) throws
    func initialise() throws
    func cleanVersions() throws
    func shouldCleanVersions(_ shouldCleanVersions:Bool)
    func shouldCleanVersions() -> Bool
}

public final class DatabaseChange {
    
    private let impl:DatabaseChangeImplement
    
    public init(impl: DatabaseChangeImplement){
        self.impl = impl
    }
    
    public func createSequence(name:String) throws {
        let definition = DatabaseTableDefinition(name: name, action: .createSequence)
        try self.impl.apply(change: definition)
    }
    
    public func dropSequence(name:String) throws {
        let definition = DatabaseTableDefinition(name: name, action: .dropSequence)
        try self.impl.apply(change: definition)
    }
    
    public func create(table name: String, body collect:(DatabaseTableDefinition) -> Void) throws {
        let definition = DatabaseTableDefinition(name: name, action: .create)
        collect(definition)
        try self.impl.apply(change: definition)
    }
    
    public func alter(table name: String, body collect: (DatabaseTableDefinition) -> Void) throws {
        let alteration = DatabaseTableDefinition(name: name, action: .alter)
        collect(alteration)
        try self.impl.apply(change: alteration)
    }
    
    public func drop(table name: String) throws {
        let drop = DatabaseTableDefinition(name: name, action: .drop)
        try self.impl.apply(change: drop)
    }
    
    public func create(trigger name: String, when: DatabaseTriggerWhen, action: DatabaseTriggerEvent, on table: String, level: DatabaseTriggerLevel, function: String, body: String) throws {
        let trigger = DatabaseTriggerDefinition(action: .create, name: name, table: table)
        trigger.when(when)
            .event(action)
            .level(level)
            .function(name: function, body: body)
        try self.impl.apply(change: trigger)
        
    }
    
    public func drop(trigger name:String, on table: String) throws {
        let change = DatabaseTriggerDefinition(action: .drop, name: name, table: table)
        try self.impl.apply(change: change)
    }
    
    public func enable(trigger name: String, on table:String) throws {
        let change = DatabaseTriggerDefinition(action: .enable, name: name, table: table)
        try self.impl.apply(change: change)
    }
    
    public func disable(trigger name:String, on table:String) throws {
        let change = DatabaseTriggerDefinition(action: .disable, name: name, table: table)
        try self.impl.apply(change: change)
    }
    
    
    
    public func update(sql:String) throws {
        let update = DatabaseTableDefinition(sql: sql)
        try self.impl.apply(change: update)
    }
    
    public func execute(sql:String) throws {
        let update = DatabaseTableDefinition(sql: sql)
        try self.impl.apply(change: update)
    }
}

public final class DefaultDatabaseChangeImplementer : DatabaseChangeImplement {
    
    private let sqlGenerator:SchemaSQLGenerator
    private let sqlExecutor:DBExecutor
    
    public init(sqlExecutor:DBExecutor) {
        self.sqlExecutor = sqlExecutor
        self.sqlGenerator = sqlExecutor.getSchemaSQLGenerator()
    }
    
    private var _shouldCleanVersions = false
    
    public func shouldCleanVersions(_ shouldCleanVersions: Bool) {
        self._shouldCleanVersions = shouldCleanVersions
    }
    
    public func shouldCleanVersions() -> Bool {
        return self._shouldCleanVersions
    }
    
    public func apply(change: DatabaseTableDefinition) throws {
        let sqls = self.sqlGenerator.transform(change)
        for sql in sqls {
            try self.sqlExecutor.execute(sql: sql)
        }
    }
    
    public func apply(change: DatabaseTriggerDefinition) throws {
        let sqls = self.sqlGenerator.transform(change)
        for sql in sqls {
            try self.sqlExecutor.execute(sql: sql)
        }
    }
    
    public func exists(version: String) throws -> Bool {
        let count = try self.sqlExecutor.count(sql: self.sqlGenerator.exists(version: version))
        return count > 0
    }
    
    public func add(version:String) throws {
        try self.sqlExecutor.execute(sql: self.sqlGenerator.add(version: version))
    }
    
    public func initialise() throws {
        try self.sqlExecutor.execute(sql: self.sqlGenerator.initialise())
    }
    
    public func cleanVersions() throws {
        try self.sqlExecutor.execute(sql: self.sqlGenerator.cleanVersions())
    }
    
}


public final class DatabaseVersionMigrator {
    
    let logger = LoggerFactory.get(category: "DB", subCategory: "ModelFactory:DatabaseVersionMigrator")
    
    var versions:[String] = []
    var migrators:[String : ((DatabaseChange) throws -> Void)] = [:]
    
    private let impl: DatabaseChangeImplement
    private let sqlExecutor:DBExecutor
    
    public init(_ sqlExecutor:DBExecutor) {
        self.sqlExecutor = sqlExecutor
        self.impl = DefaultDatabaseChangeImplementer(sqlExecutor: sqlExecutor)
    }
    
    public func dropBeforeCreate(_ dropBeforeCreate:Bool) -> Self {
        let _ = self.sqlExecutor.getSchemaSQLGenerator().dropBeforeCreate(dropBeforeCreate)
        return self
    }
    
    public func cleanVersions(_ cleanVersions:Bool) -> Self {
        let _ = self.impl.shouldCleanVersions(cleanVersions)
        return self
    }
    
    public func version(_ version:String, migrate: @escaping (DatabaseChange) throws -> Void) {
        self.migrators[version] = migrate
        self.versions.append(version)
    }
    
    public func migrate() throws {
        if versions.count > 0 {
            let database = DatabaseChange(impl: impl)
            self.logger.log(.trace, "Initializing schema version record")
            try impl.initialise()
            if self.impl.shouldCleanVersions() {
                self.logger.log(.trace, "Requested to delete all schema version records")
                try impl.cleanVersions()
            }
            for version in versions {
                self.logger.log(.trace, "Looking for schema version \(version)")
                if let migration = migrators[version] {
                    if try !impl.exists(version: version) {
                        self.logger.log(.trace, "Applying schema version \(version) ...")
                        try migration(database)
                        try impl.add(version: version)
                    }else{
                        self.logger.log(.trace, "Schema version \(version) already exist, ignored.")
                    }
                }
            }
        }
    }
}




