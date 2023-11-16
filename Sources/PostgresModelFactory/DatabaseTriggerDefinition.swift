//
//  DatabaseTriggerDefinition.swift
//
//  Created by Kelvin Wong on 2023/7/23.
//

import Foundation

public enum DatabaseTriggerAction {
    
    case create
    case drop
    case enable
    case disable
    
}

public enum DatabaseTriggerWhen {
    case before
    case after
    case none
    
    func string() -> String {
        switch self{
        case .before:
            return "BEFORE"
        case .after:
            return "AFTER"
        default:
            return ""
        }
    }
}

public enum DatabaseTriggerEvent {
    case insert
    case update
    case delete
    case truncate
    case none
    
    func string() -> String {
        switch self{
        case .insert:
            return "INSERT"
        case .update:
            return "UPDATE"
        case .delete:
            return "DELETE"
        case .truncate:
            return "TRUNCATE"
        default:
            return ""
        }
    }
}

public enum DatabaseTriggerLevel {
    case forEachRow
    case forEachStatement
    case none
    
    func string() -> String {
        switch self {
        case .forEachRow:
            return "FOR EACH ROW"
        case .forEachStatement:
            return "FOR EACH STATEMENT"
        default:
            return ""
        }
    }
}

public final class DatabaseTriggerDefinition {
    
    private var action:DatabaseTriggerAction
    private var name:String
    private var when:DatabaseTriggerWhen?
    private var event:DatabaseTriggerEvent?
    private var table:String
    private var level:DatabaseTriggerLevel?
    private var functionName:String?
    private var functionBody:String?
    
    public init(action:DatabaseTriggerAction, name:String, table:String) {
        self.action = action
        self.name = name
        self.table = table
    }
    
    public func when(_ when:DatabaseTriggerWhen) -> DatabaseTriggerDefinition {
        self.when = when
        return self
    }
    
    public func event(_ event:DatabaseTriggerEvent) -> DatabaseTriggerDefinition {
        self.event = event
        return self
    }
    
    public func level(_ level:DatabaseTriggerLevel) -> DatabaseTriggerDefinition {
        self.level = level
        return self
    }
    
    public func function(name:String, body:String) {
        self.functionName = name
        self.functionBody = body
    }
    
    public func getAction() -> DatabaseTriggerAction {
        return self.action
    }
    
    public func getName() -> String {
        return self.name
    }
    
    public func getWhen() -> DatabaseTriggerWhen? {
        return self.when
    }
    
    public func getEvent() -> DatabaseTriggerEvent? {
        return self.event
    }
    
    public func getTable() -> String {
        return self.table
    }
    
    public func getLevel() -> DatabaseTriggerLevel? {
        return self.level
    }
    
    public func getFunctionName() -> String? {
        return self.functionName
    }
    
    public func getFunctionBody() -> String? {
        return self.functionBody
    }
}
