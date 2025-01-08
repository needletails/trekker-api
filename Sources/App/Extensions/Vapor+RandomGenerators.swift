//
//  Vapor+RandomGenerators.swift
//  trekker-api
//
//  Created by NeedleTails App BrewHub on 1/7/25.
//
import Vapor
import NIOConcurrencyHelpers

extension Application.RandomGenerators.Provider {
    static var random: Self {
        .init {
            $0.randomGenerators.use { _ in RealRandomGenerator() }
        }
    }
}

struct RealRandomGenerator: RandomGenerator {
    func generate(bits: Int) -> String {
        [UInt8].random(count: bits / 8).hex
    }
}

public protocol RandomGenerator {
    func generate(bits: Int) -> String
}

extension Application {
    public struct RandomGenerators {
        let lock = NIOLock()
        
        public struct Provider {
            let run: ((Application) -> Void)
        }
        
        public let app: Application
        
        
        public func use(_ provider: Provider) {
            provider.run(app)
        }
        
        public func use(_ makeGenerator: @escaping ((Application) -> RandomGenerator)) {
            lock.lock()
            defer { lock.unlock() }
            storage.makeGenerator = makeGenerator
        }
        
        actor Storage {
            //Is safe because on setting the variable we are protecting with an actor
            nonisolated(unsafe) var makeGenerator: ((Application) -> RandomGenerator)?
            init() {}
        }
        
        private struct Key: StorageKey {
            typealias Value = Storage
        }
        
        var storage: Storage {
            if let existing = self.app.storage[Key.self] {
                return existing
            } else {
                let new = Storage()
                self.app.storage[Key.self] = new
                return new
            }
        }
    }
    
    public func generate(bits: Int) -> String {
        [UInt8].random(count: bits / 8).hex
    }
    
    public var randomGenerators: RandomGenerators {
        .init(app: self)
    }
}
