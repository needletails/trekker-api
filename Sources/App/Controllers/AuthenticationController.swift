//
//  AuthenticationController.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/7/25.
//
import Vapor

actor AuthenicationController {
    
    enum AuthenticationError: Error {
        case emptyPassword
        case passwordsDontMatch
        case invalidCredentials
        case missingHash
        case refreshTokenHasExpired
        case refreshTokenOrUserNotFound
        case userNotFound
        case userExists(String)
    }
    
    
    @Sendable func register(_ req: Request) async throws -> HTTPStatus {
        let registerRequest = try req.content.decode(RegisterRequest.self)
        
        guard !registerRequest.password.isEmpty else {
            throw AuthenticationError.emptyPassword
        }
        
        guard !registerRequest.confirmPassword.isEmpty else {
            throw AuthenticationError.emptyPassword
        }
        
        guard registerRequest.password == registerRequest.confirmPassword else {
            throw AuthenticationError.passwordsDontMatch
        }
        let user = User(
            id: UUID().uuidString,
            username: registerRequest.username,
            passwordHash: try Bcrypt.hash(registerRequest.password),
            isAdmin: false,
            appleIdentifier: nil
        )
        switch await req.store.createUser(user) {
        case .success:
            return .created
        case .fail(let error):
            throw error
        case .userExists(let message):
            throw AuthenticationError.userExists(message)
        }
    }
    
    @Sendable func login(_ req: Request) async throws -> LoginResponse {
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        guard let user = try await req.store.findUser(loginRequest.username) else { throw Abort(.notFound) }
        
        guard let hash = user.passwordHash else {
            throw AuthenticationError.missingHash
        }
        if try Bcrypt.verify(loginRequest.password, created: hash) {
            let token = try await req.jwt.sign(try Payload(with: user))
            
            let generated = req.application.generate(bits: 256)
            let refreshToken = RefreshToken(id: UUID().uuidString, token: SHA256.cHash(generated), user: user)
            try await req.store.create(refreshToken)
            
            return LoginResponse(user: user, accessToken: token, refreshToken: generated)
        } else {
            throw AuthenticationError.invalidCredentials
        }
    }
    
    @Sendable func refreshAccessToken(_ req: Request) async throws -> AccessTokenResponse {
        let accessTokenRequest = try req.content.decode(_RefreshToken.self)
        
        let hashedRefreshToken = SHA256.cHash(accessTokenRequest.token)
        
        if let token = try await req.store.find(token: hashedRefreshToken) {
            try await req.store.delete(token)
            if token.expiresAt > Date() {
                throw AuthenticationError.refreshTokenHasExpired
            }
            
            do {
                let generated = req.application.generate(bits: 256)
                let refreshToken = RefreshToken(token: SHA256.cHash(generated), user: token.user)
                
                let payload = try Payload(with: token.user)
                let accessToken = try await req.jwt.sign(payload)
                try await req.store.create(refreshToken)
                return AccessTokenResponse(refreshToken: generated, accessToken: accessToken, user: token.user)
            } catch {
                throw Abort(.custom(code: 512, reasonPhrase: error.localizedDescription))
            }
        } else {
            throw AuthenticationError.refreshTokenOrUserNotFound
        }
    }
    
    @Sendable func registerAppleUser(_ req: Request) async throws -> HTTPStatus {
        let identity = try await req.jwt.apple.verify()
        if (try await req.store.findUser(appleIdentifier: identity.subject.value) != nil) {
            throw AuthenticationError.userExists("User already exists")
        } else {
            let user = User(
                id: UUID().uuidString,
                username: identity.email ?? identity.subject.value,
                isAdmin: false,
                appleIdentifier: identity.subject.value)
            
            switch await req.store.createUser(user) {
            case .success:
                return .created
            case .fail(let error):
                throw error
            case .userExists(let message):
                throw AuthenticationError.userExists(message)
            }
        }
    }
    
    @Sendable func loginAppleUser(_ req: Request) async throws -> LoginResponse {
        let identity = try await req.jwt.apple.verify()
        if let user = try await req.store.findUser(appleIdentifier: identity.subject.value) {
            try await req.store.delete(for: user.id)
            let token = try await req.jwt.sign(try Payload(with: user))
            let generated = req.application.generate(bits: 256)
            let refreshToken = RefreshToken(id: UUID().uuidString, token: SHA256.cHash(generated), user: user)
            try await req.store.create(refreshToken)
            return LoginResponse(user: user, accessToken: token, refreshToken: generated)
        } else {
            throw AuthenticationError.userNotFound
        }
    }
    
    @Sendable func deleteRefreshToken(_ req: Request) async throws -> HTTPStatus {
        let refreshToken = try req.content.decode(_RefreshToken.self)
        let hashedRefreshToken = SHA256.cHash(refreshToken.token)
        
        if let token = try await req.store.find(token: hashedRefreshToken) {
            try await req.store.delete(token)
            return .ok
        } else {
            throw AuthenticationError.refreshTokenOrUserNotFound
        }
    }
    
    @Sendable func deleteUser(_ req: Request) async throws -> HTTPStatus {
        let user = try req.content.decode(DeleteUser.self)
        if let appleIdentity = user.appleIdentity {
            if let user = try await req.store.findUser(appleIdentifier: appleIdentity) {
                try await req.store.deleteUser(appleIdentifier: appleIdentity)
                try await req.store.deleteAllTokens(for: user.username)
                return .ok
            } else {
                return .notFound
            }
        } else {
            if let username = user.username, let user = try await req.store.findUser(username) {
                try await req.store.deleteUser(user.username)
                try await req.store.deleteAllTokens(for: user.username)
                return .ok
            } else {
                return .notFound
            }
        }
        
    }
}
