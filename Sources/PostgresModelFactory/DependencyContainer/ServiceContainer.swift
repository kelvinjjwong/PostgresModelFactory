//
//  ServiceContainer.swift
//
//
//  Created by kelvinwong on 2023/11/17.
//

import Foundation

@propertyWrapper
struct Autowired<Service> {
    
    var service: Service
    
    init(name:String = "", _ dependencyType: ServiceType = .newInstance) {
        guard let service = ServiceContainer.resolve(name:name, dependencyType: dependencyType, Service.self) else {
            fatalError("No dependency of type \(String(describing: Service.self)) registered!")
        }
        
        self.service = service
    }
    
    var wrappedValue: Service {
        get { self.service }
        mutating set { service = newValue }
    }
}

final class ServiceContainer {
    
    private static var cache: [String: Any] = [:]
    private static var services: [String: () -> Any] = [:]
    
    static func register<Service>(name:String = "", type: Service.Type, as serviceType: ServiceType = .automatic, _ factory: @autoclosure @escaping () -> Service) {
        var key = String(describing: type.self)
        if name != "" {
            key = "\(key)#\(name)"
        }
        
        services[key] = factory
        
        if serviceType == .singleton {
            cache[key] = factory()
        }
    }
    
    static func resolve<Service>(name:String = "", dependencyType: ServiceType = .automatic, _ type: Service.Type) -> Service? {
        var key = String(describing: type.self)
        if name != "" {
            key = "\(key)#\(name)"
        }
        return resolve(key: key, dependencyType: dependencyType, type: type)        
    }
    
    private static func resolve<Service>(key:String, dependencyType: ServiceType, type: Service.Type) -> Service? {
        switch dependencyType {
        case .singleton:
            if let cachedService = cache[key] as? Service {
                return cachedService
            } else {
                fatalError("\(String(describing: type.self)) is not registeres as singleton")
            }
            
        case .automatic:
            if let cachedService = cache[key] as? Service {
                return cachedService
            }
            fallthrough
            
        case .newInstance:
            if let service = services[key]?() as? Service {
                cache[String(describing: type.self)] = service
                return service
            } else {
                return nil
            }
        }
    }
}

enum ServiceType {
    case singleton
    case newInstance
    case automatic
}
