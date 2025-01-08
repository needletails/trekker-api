import Vapor
import JWTKit

// configures your application
public func configure(_ app: Application) async throws {

    /// Dockerized containers need to have the host name set to 0.0.0.0 in order for it to be accessed outside of the container
    /// For example if NGINX is trying to access the port.
    app.http.server.configuration = .init(hostname: "0.0.0.0",
                                        port: 8080,
                                        supportVersions: Set<HTTPVersionMajor>([.one]),
                                        tlsConfiguration: .none,
                                        serverName: "TrekkerAPI",
                                        logger: Logger(label: "[trekker-api]"))
    
    //Initialize the database
    try app.initializeMongoDB(connectionString: "\(app.config.mongoURL)")
    
    //Create the Database store
    app.createStore()

    await app.jwt.keys.add(hmac: app.config.hmacSecret, digestAlgorithm: .sha256)
    app.jwt.apple.applicationIdentifier = app.config.applicationIdentifier
    
    app.middleware = .init()
    //Use to protect against CSRF Attacks
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .OPTIONS, .PUT, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin])
    
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    app.middleware.use(corsMiddleware)
    
    //Our Route logging
    let routeLogging = RouteLoggingMiddleware(logLevel: .info)
    app.middleware.use(routeLogging)
    
    //Our Error Reporter
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    //API Log level
    app.logger.logLevel = .trace
    
    try routes(app)
    print(app.routes)
}
