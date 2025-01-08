import Vapor

func routes(_ app: Application) throws {
    let api = app.grouped("api")
    let auth = api.grouped("auth")
    let tokenProtected = auth.grouped("protected")
        .grouped(Payload.authenticator(), Payload.guardMiddleware())
    
    
    let authHandler = AuthenicationController()
    auth.post("register", use: authHandler.register)
    auth.post("login", use: authHandler.login)
    auth.post("refresh", use: authHandler.refreshAccessToken)
    auth.post("siwa-register", use: authHandler.registerAppleUser)
    auth.post("siwa-login", use: authHandler.loginAppleUser)
    tokenProtected.post("logout", use: authHandler.deleteRefreshToken)
    tokenProtected.post("delete-account", use: authHandler.deleteUser)
}
