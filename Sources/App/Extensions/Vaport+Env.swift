//
//  Vaport+Env.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/7/25.
//
import Vapor
import JWTKit

struct EnvironmentVariables {
    let mongoURL: String
    let applicationIdentifier: String
    let hmacSecret: HMACKey
    
    static var environment: EnvironmentVariables {
        let mongoURL = Environment.get("MONGO_URL") ?? ""
        let applicationIdentifier = Environment.get("APPLICATION_ID") ?? ""
        let hmacSecret = Environment.get("HMAC_SECRET") ?? ""
        return .init(mongoURL: mongoURL, applicationIdentifier: applicationIdentifier, hmacSecret: HMACKey(stringLiteral: hmacSecret))
    }
}


extension Application {
    
    struct AppConfigKey: StorageKey {
        typealias Value = EnvironmentVariables
    }
    
    var config: EnvironmentVariables {
        get {
            storage[AppConfigKey.self] ?? .environment
        }
        set {
            storage[AppConfigKey.self] = newValue
        }
    }
}
