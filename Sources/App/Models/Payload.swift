//
//  Payload.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/7/25.
//
import Vapor
import JWT

/// How long should access tokens live for. Default: 2 hours (in seconds)
let ACCESS_TOKEN_LIFETIME: Double = 60 * 60 * 2
//    60 * 60 * 2/
/// How long should refresh tokens live for: Default: 7 days (in seconds)
let REFRESH_TOKEN_LIFETIME: Double = 60 * 60 * 24 * 7

public struct Payload: JWTPayload, Authenticatable, Sendable {
    
    // User-releated stuff
    var id: String
    var username: String
    var appleIdentifier: String?
    var isAdmin: Bool
    // JWT stuff
    var exp: ExpirationClaim
    
    init(with user: User) throws {
        self.id = user.id
        self.username = user.username
        self.appleIdentifier = user.appleIdentifier
        self.isAdmin = user.isAdmin
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(ACCESS_TOKEN_LIFETIME))
    }
    
    public func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
    }
}

extension User {
    init(from payload: Payload) {
        self.init(id: payload.id, username: payload.username, isAdmin: payload.isAdmin, appleIdentifier: payload.appleIdentifier)
    }
}


public struct RefreshToken: Codable, Equatable, Sendable {
    
    public var id: String?
    public var token: String
    public var user: User
    public var expiresAt: Date
    public var issuedAt: Date
    
    init(
        id: String,
        token: String,
        user: User,
        expiresAt: Date = Date().addingTimeInterval(REFRESH_TOKEN_LIFETIME),
        issuedAt: Date = Date()
    ) {
        self.id = id
        self.token = token
        self.user = user
        self.expiresAt = expiresAt
        self.issuedAt = issuedAt
    }
    
    init(
        token: String,
        user: User
    ) {
        self.token = token
        self.user = user
        self.expiresAt = Date().addingTimeInterval(REFRESH_TOKEN_LIFETIME)
        self.issuedAt = Date()
    }
    
    public static func == (lhs: RefreshToken, rhs: RefreshToken) -> Bool {
        return lhs.id == rhs.id
    }
}

struct AccessTokenResponse: Content {
    let refreshToken: String
    let accessToken: String
    let user: User
}

struct _RefreshToken: Codable {
    let token: String
}
