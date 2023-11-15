//
//  DatabaseValueConvertible.swift
//  
//
//  Created by kelvinwong on 2023/11/12.
//

import Foundation
import PostgresClientKit

public protocol DatabaseValueConvertible :  PostgresValueConvertible{
}

extension String : DatabaseValueConvertible {}
extension Int : DatabaseValueConvertible {}
extension Double : DatabaseValueConvertible {}
extension Decimal : DatabaseValueConvertible {}
extension Bool : DatabaseValueConvertible {}
extension PostgresByteA : DatabaseValueConvertible {}
extension PostgresDate : DatabaseValueConvertible {}
extension PostgresTime : DatabaseValueConvertible {}
extension PostgresTimeWithTimeZone : DatabaseValueConvertible {}
extension PostgresTimestamp : DatabaseValueConvertible {}
extension PostgresTimestampWithTimeZone : DatabaseValueConvertible {}
extension PostgresValue : DatabaseValueConvertible {}
