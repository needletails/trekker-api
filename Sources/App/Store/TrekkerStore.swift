//
//  TrekkerStore.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/8/25.
//
import MongoKitten

protocol Store: Sendable {
    func findUsers() async throws -> [User]?
    func findUser(_ username: String) async throws -> User?
    func findUser(appleIdentifier: String) async throws -> User?
    func createUser(_ user: User) async -> CreateUserResult
    func updateUser(_ username: String, update user: User) async throws
    func deleteUser(_ username: String) async throws
    
    func create(_ token: RefreshToken) async throws
    func findTokens() async throws -> [RefreshToken]
    func find(id: String) async throws -> RefreshToken?
    func find(token: String) async throws -> RefreshToken?
    func delete(_ token: RefreshToken) async throws
    func count() async throws -> Int
    func delete(for userID: String) async throws
    func deleteUser(appleIdentifier: String) async throws
    func deleteAllTokens(for username: String) async throws
}


public actor TrekkerStore: Store {
    
    let mongoDB: MongoDatabase
    var userCollection: MongoCollection
    var tokensCollection: MongoCollection
    
    init(mongoDB: MongoDatabase) {
        self.mongoDB = mongoDB
        self.userCollection = mongoDB["users1"]
        self.tokensCollection = mongoDB["tokens1"]
    }
    
    func dropdatabase() async throws {}
    
    enum Errors: Error {
        case userNotFound, tokenNotFound
    }
    
    func findUsers() async throws -> [User]? {
        var users = [User]()
        
        let batch = try await userCollection.find().execute().nextBatch()
        for item in batch {
            let user = try BSONDecoder().decode(User.self, from: item)
            users.append(user)
        }
        return users
    }
    
    func findUser(_ username: String) async throws -> User? {
        return try await self.findUsers()?.first(where: { $0.username == username })
    }
    
    func findUser(appleIdentifier: String) async throws -> User? {
        return try await self.findUsers()?.first(where: { $0.appleIdentifier == appleIdentifier })
        }
    
    func createUser(_ user: User) async -> CreateUserResult {
        do {
            if try await self.findUsers()?.first(where: { $0.username == user.username }) != nil {
                return .userExists("User Exists")
            } else {
                let data = try BSONEncoder().encode(user)
                try await userCollection.insert(data)
                return .success
            }
        } catch {
            return .fail(error)
        }
    }
    
    func updateUser(_ username: String, update user: User) async throws {
        guard let oldUser = try await self.findUsers()?.first(where: { $0.username == username }) else { throw Errors.userNotFound }
        let oldDocument = try BSONEncoder().encode(oldUser)
        let newDocument = try BSONEncoder().encode(user)
        _ = try await userCollection.updateOne(where: oldDocument, to: newDocument)
    }
    
    func deleteUser(_ username: String) async throws {
        guard let oldUser = try await self.findUsers()?.first(where: { $0.username == username }) else { throw Errors.userNotFound }
        let doc = try BSONEncoder().encode(oldUser)
        _ = try await userCollection.deleteOne(where: doc)
    }
    
    func deleteUser(appleIdentifier: String) async throws {
        guard let oldUser = try await self.findUsers()?.first(where: { $0.appleIdentifier == appleIdentifier }) else { throw Errors.userNotFound }
        let doc = try BSONEncoder().encode(oldUser)
        _ = try await userCollection.deleteOne(where: doc)
    }
}


extension TrekkerStore {
    
    func create(_ token: RefreshToken) async throws {
        let data = try BSONEncoder().encode(token)
        try await tokensCollection.insert(data)
    }
    
    func findTokens() async throws -> [RefreshToken] {
        var tokens = [RefreshToken]()
        
        let batch = try await tokensCollection.find().execute().nextBatch()
        for item in batch {
            let token = try BSONDecoder().decode(RefreshToken.self, from: item)
            tokens.append(token)
        }
        return tokens
    }
    
    func find(id: String) async throws -> RefreshToken? {
        return try await self.findTokens().first(where: { $0.id == id })
    }
    
    func find(token: String) async throws -> RefreshToken? {
        return try await self.findTokens().first(where: { $0.token == token })
    }
    
    func delete(_ token: RefreshToken) async throws {
       guard let oldUser = try await self.findTokens().first(where: { $0.token == token.token }) else { throw Errors.userNotFound }
        let doc = try BSONEncoder().encode(oldUser)
        _ = try await tokensCollection.deleteOne(where: doc)
    }
    
    func count() async throws -> Int {
        return try await findTokens().count
    }
    
    func delete(for userID: String) async throws {
        guard let token = try await self.findTokens().first(where: { $0.user.username == userID }) else { return }
        let doc = try BSONEncoder().encode(token)
        _ = try await tokensCollection.deleteOne(where: doc)
    }
    
    func deleteAllTokens(for username: String) async throws {
        for token in try await self.findTokens().filter({ $0.user.username == username }) {
            let doc = try BSONEncoder().encode(token)
            _ = try await tokensCollection.deleteOne(where: doc)
        }
    }
}
