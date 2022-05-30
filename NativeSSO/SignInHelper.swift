//
//  SignInHelper.swift
//  NativeSSO
//
//  Created by Huan Liu on 8/17/21.
//

import OktaOidc


class SignInHelper: NSObject {

    static let issuer = "https://huanliu.trexcloud.com/oauth2/default"
    static let authorizeUrl = "https://huanliu.trexcloud.com/oauth2/default/v1/authorize"
    static let tokenUrl = "https://huanliu.trexcloud.com/oauth2/default/v1/token"
    
    static let keychainGroup = "96XG5CYU7R.com.atko.group"
    static let keychainTag = "device_secret"
    static var stateManager : OktaOidcStateManager?
    
    static func doLogin(oktaOidc: OktaOidc, browserOidcLogin: @escaping ()->(),
                        successHandler: @escaping (_ stateManager: OktaOidcStateManager?)->()) {
        // we are here when we are not logged in
        // first try to find device_secret and exchange a token
        let (idToken, deviceSecret) = queryForDeviceSecret()
        if idToken == nil {
            browserOidcLogin()
            return
        }
        
        // try exchange for token
        let configuration = OKTServiceConfiguration.init(
            authorizationEndpoint: URL(string: authorizeUrl)!,
            tokenEndpoint: URL(string: tokenUrl)!
        )

        let request = OKTTokenRequest(configuration: configuration,
                                      grantType: "urn:ietf:params:oauth:grant-type:token-exchange",
                                      authorizationCode: nil,
                                      redirectURL: nil,
                                      clientID: oktaOidc.configuration.clientId,
                                      clientSecret: nil,
                                      scope: "openid offline_access",
                                      refreshToken: nil,
                                      codeVerifier: nil,
                                      additionalParameters: ["actor_token" : deviceSecret!,
                                                             "actor_token_type" : "urn:x-oath:params:oauth:token-type:device-secret",
                                                             "subject_token" : idToken!,
                                                             "subject_token_type" : "urn:ietf:params:oauth:token-type:id_token",
                                                             "audience" : "api://default"]) 
        // perform token exchange
        OKTAuthorizationService.perform(request, delegate: nil) { tokenResponse, error in
            if error != nil {
                print(error!)
                // could not exchange DeviceToken, fall back to regular login
                browserOidcLogin()
                return
            }
            
            // successfully exchanged token, try to save
            // construct AuthState from a fake request, because we did not make a real OIDC request to begin with
            let authState = OKTAuthState(authorizationResponse:
                                         OKTAuthorizationResponse(request:
                                                                    OKTAuthorizationRequest(configuration: configuration,
                                                                                            clientId: oktaOidc.configuration.clientId,
                                                                                            scopes: ["openid"],
                                                                                            redirectURL: URL(string: "any")!,
                                                                                            responseType: "code",
                                                                                            additionalParameters: nil),
                                                                                    parameters: ["any": "any" as NSString]))
            // tokenResponse has the real tokens that we need to save
            authState.update(with: tokenResponse, error: error)
            
            let sm = OktaOidcStateManager(authState: authState)
            // Store instance of stateManager into the local iOS keychain
            sm.writeToSecureStorage()
            stateManager = sm
            
            successHandler(stateManager)
        }
    }

    // callback from Browser login to save the state as necessary
    static let oktaOidcCallback: (OktaOidcStateManager?, Error?) -> () = { stateManager, error in
        if let error = error {
            // Error
            return
        }
        
        SignInHelper.stateManager = stateManager
        
        // #1 Store instance of stateManager into the local iOS keychain
        stateManager!.writeToSecureStorage()

        // #2 Use tokens
        print(stateManager!.accessToken!)
        print(stateManager!.idToken!)
        print(stateManager!.refreshToken!)
        print(stateManager!.authState.lastTokenResponse!.additionalParameters!["device_secret"]!)

        // persist in iCloud keychain
        // can update key, but it is easier to understand to just remove and add
        removeDeviceSecret()
        addDeviceSecret(idToken: stateManager!.idToken!, deviceSecret: stateManager!.authState.lastTokenResponse!.additionalParameters!["device_secret"]! as! String)
    }
    
    
    static func queryForDeviceSecret() -> (idToken: String?, deviceSecret: String?) {
        let query: [String: Any] = [
            (kSecClass as String): kSecClassGenericPassword,   // only Password items can use iCloud keychain
            (kSecAttrSynchronizable as String): kCFBooleanTrue!,  // allow iCloud
            (kSecAttrLabel as String): keychainTag,       // tag to make it easy to search
            (kSecAttrAccessGroup as String): keychainGroup,   // multiple apps can share through this group
            (kSecMatchLimit as String): kSecMatchLimitOne,    // should only have one key
            (kSecReturnAttributes as String): true,
            (kSecReturnData as String): true]
        var item: CFTypeRef?

        // should succeed
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        print(SecCopyErrorMessageString(status, nil) ?? "")
        
        if let existingItem = item as? [String: Any],
            let idToken = existingItem[kSecAttrAccount as String] as? String,
            let deviceSecretData = existingItem[kSecValueData as String] as? Data {
            let deviceSecret = String(data: deviceSecretData, encoding: .utf8)
            return (idToken, deviceSecret)
        }
        return (nil, nil)
    }

    static func addDeviceSecret(idToken: String, deviceSecret: String) {
        let attributes: [String: Any] = [
            (kSecClass as String): kSecClassGenericPassword,    // only Password items can use iCloud keychain
            (kSecAttrSynchronizable as String): kCFBooleanTrue!,  // allow iCloud
            (kSecAttrLabel as String): keychainTag,        // tag to make it easy to search
            (kSecAttrAccessGroup as String): keychainGroup,   // multiple apps can share through this group
            (kSecAttrAccount as String): idToken,
            (kSecValueData as String): deviceSecret.data(using: .utf8)!
        ]
        // Let's add the item to the Keychain! 😄
        let status = SecItemAdd(attributes as CFDictionary, nil)
        print(SecCopyErrorMessageString(status, nil) ?? "")
    }
    
    static func removeDeviceSecret() {
        let query: [String: Any] = [
            (kSecClass as String): kSecClassGenericPassword,  // only Password items can use iCloud keychain
            (kSecAttrSynchronizable as String): kCFBooleanTrue!,  // allow iCloud
            (kSecAttrAccessGroup as String): keychainGroup,   // multiple apps can share through this group
            (kSecAttrLabel as String): keychainTag]      // tag to make it easy to search

        let status = SecItemDelete(query as CFDictionary)
        print(SecCopyErrorMessageString(status, nil) ?? "")
    }
    
}
