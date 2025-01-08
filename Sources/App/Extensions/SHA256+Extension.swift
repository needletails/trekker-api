//
//  SHA256+Extension.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/7/25.
//
import Crypto
import Foundation

extension SHA256 {
//    /// Returns hex-encoded string
    static func cHash(_ string: String) -> String {
        SHA256.cHash(data: string.data(using: .utf8)!)
    }
    
    /// Returns a hex encoded string
    static func cHash<D>(data: D) -> String where D : DataProtocol {
        SHA256.hash(data: data).hex
    }
}
