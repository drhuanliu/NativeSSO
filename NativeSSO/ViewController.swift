//
//  ViewController.swift
//  NativeSSO
//
//  Created by Huan Liu on 7/29/21.
//

import UIKit
import OktaOidc

class ViewController: UIViewController {

    var oktaOidc : OktaOidc!
    var stateManager : OktaOidcStateManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        do {
            
            let configuration = try OktaOidcConfig(with: [
//                "issuer": "https://dev-57525606.okta.com/oauth2/default",
//                "clientId": "0oa15wulqt5yqD9FP5d7",
                "issuer": "https://huanliu.trexcloud.com/oauth2/default",
                "clientId": "0oa826j5pHmPRt2n00w6",
//                "scopes": "openid profile offline_access",
                "scopes": "device_sso openid offline_access",
                "redirectUri": "nativesso:/callback",
                "logoutRedirectUri": "nativesso:/logout"
            ])
            
            oktaOidc = try OktaOidc(configuration: configuration)
            
        }
        catch {}
//        OIDAuthorizationService.perform(<#T##request: OIDTokenRequest##OIDTokenRequest#>, callback: <#T##OIDTokenCallback##OIDTokenCallback##(OIDTokenResponse?, Error?) -> Void#>)
//        let  a = OktaOidcStateManager(authState: nil)

    }
    

    @IBAction func login(_ sender: Any) {
        
        queryForDeviceSecret()
        addDeviceSecret(accessToken: "acct", deviceSecret: "secret")
        queryForDeviceSecret()
//        removeDeviceSecret()
        
        oktaOidc.signInWithBrowser(from: self) { stateManager, error in
            if let error = error {
                // Error
                return
            }
            
            self.stateManager = stateManager
            
            // #1 Store instance of stateManager into the iOS keychain
            stateManager!.writeToSecureStorage()

            // how to read
           // authStateManager = OktaOidcStateManager.readFromSecureStorage(for: config)

            // #2 Use tokens
            print(stateManager!.accessToken!)
            print(stateManager!.idToken!)
            print(stateManager!.refreshToken!)
            print(stateManager!.authState.lastTokenResponse!.additionalParameters!["devie_secret"]!)

            stateManager?.getUser { response, error in
                if let error = error {
                    // Error
                    return
                }

                // response is Dictionary - [String:Any]
                let username = response?["preferred_username"] as? String
                let email = response?["email"] as? String
            }
            
        }
                    
    }
    
    @IBAction func logout(_ sender: Any) {
        oktaOidc.signOutOfOkta(self.stateManager!, from: self) { error in
            if let error = error {
                // Handle error
                return
            }
        }
    }
    
    
    func queryForDeviceSecret() {
        let query: [String: Any] = [
            (kSecClass as String): kSecClassGenericPassword,
            (kSecAttrSynchronizable as String): kCFBooleanTrue,  // allow iCloud
            (kSecAttrLabel as String): "device_secret",
            (kSecMatchLimit as String): kSecMatchLimitOne,
            (kSecReturnAttributes as String): true,
            (kSecReturnData as String): true]
        var item: CFTypeRef?

        // should succeed
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        print(SecCopyErrorMessageString(status, nil))
        
        if let existingItem = item as? [String: Any],
            let accessToken = existingItem[kSecAttrAccount as String] as? String,
            let deviceSecretData = existingItem[kSecValueData as String] as? Data {
            let deviceSecret = String(data: deviceSecretData, encoding: .utf8)
            print("\(accessToken) - \(deviceSecret)")
        }
    }
     
    func addDeviceSecret(accessToken: String, deviceSecret: String) {
        let attributes: [String: Any] = [
            (kSecClass as String): kSecClassGenericPassword,
            (kSecAttrSynchronizable as String): kCFBooleanTrue,  // allow iCloud
            (kSecAttrLabel as String): "device_secret",
            (kSecAttrAccount as String): accessToken,
            (kSecValueData as String): deviceSecret.data(using: .utf8)!
        ]
        // Let's add the item to the Keychain! 😄
        let status = SecItemAdd(attributes as CFDictionary, nil)
        print(SecCopyErrorMessageString(status, nil))

    }
    
    func removeDeviceSecret() {
        let query: [String: Any] = [
            (kSecClass as String): kSecClassGenericPassword,
            (kSecAttrLabel as String): "device_secret"]

        let status = SecItemDelete(query as CFDictionary)
        print(SecCopyErrorMessageString(status, nil))
    }
        
}

