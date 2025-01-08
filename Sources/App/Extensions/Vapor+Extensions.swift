//
//  Vapor+Extensions.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/7/25.
//
import Vapor
import MongoKitten


extension Request {

    public var store: TrekkerStore {
        application.store
    }

    public var mongoDB: MongoDatabase {
        return application.mongoDB
    }
}

private struct MongoDBStorageKey: StorageKey {
    typealias Value = MongoDatabase
}

private struct StoreStorageKey: StorageKey {
    typealias Value = TrekkerStore
}


extension Application {
    
    public var store: TrekkerStore {
        get {
            storage[StoreStorageKey.self]!
        }
        set {
            storage[StoreStorageKey.self] = newValue
        }
    }
    
    public func createStore() {
        self.store = TrekkerStore(mongoDB: mongoDB)
    }
    
    public func dropDatabase() async throws {
        try await self.store.dropdatabase()
    }

    public var mongoDB: MongoDatabase {
        get {
            storage[MongoDBStorageKey.self]!
        }
        set {
            storage[MongoDBStorageKey.self] = newValue
        }
    }
    
    public func initializeMongoDB(connectionString: String) throws {
        self.mongoDB = try MongoDatabase.lazyConnect(to: connectionString)
    }
}
