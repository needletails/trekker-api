//
//  User.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/7/25.
//
import Vapor

// Define a struct for the login request body
struct LoginRequest: Content, Sendable {
    let username: String
    let password: String
}

// Define a struct for the login response
struct LoginResponse: Content, Sendable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct RegisterRequest: Content, Sendable {
    var username: String
    var password: String
    var confirmPassword: String
    var apple: String?
}

enum CreateUserResult: Sendable {
    case success, fail(Error), userExists(String)
}

public struct User: Codable, Sendable {
    
    var id: String
    let username: String
    let passwordHash: String?
    var isAdmin: Bool
    var appleIdentifier: String?
    let metadata: Data?
    
    init(
        id: String,
        username: String,
        passwordHash: String? = nil,
        isAdmin: Bool,
        appleIdentifier: String?,
        metadata: Data? = nil
    ) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.isAdmin = isAdmin
        self.appleIdentifier = appleIdentifier
        self.metadata = metadata
    }
}

struct DeleteUser: Codable {
    var appleIdentity: String?
    var username: String?
    var passwordHash: String?
}
