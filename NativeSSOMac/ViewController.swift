//
//  ViewController.swift
//  NativeSSOMac
//
//  Created by Huan Liu on 8/14/21.
//

import Cocoa
import OktaOidc
import JWTDecode

class ViewController: NSViewController {

    var oktaOidc : OktaOidc!
    @IBOutlet weak var label: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            let configuration = try OktaOidcConfig(with: [
                "issuer": SignInHelper.issuer,
                "clientId": "0oa826zpzWsYQDetm0w6",
                "scopes": "device_sso openid offline_access",
                "redirectUri": "nativesso:/callback",
                "logoutRedirectUri": "nativesso:/logout"
            ])
                
            oktaOidc = try OktaOidc(configuration: configuration)

            SignInHelper.stateManager = OktaOidcStateManager.readFromSecureStorage(for: configuration)

            displayUsername(SignInHelper.stateManager)
        }
        catch {
            print(error)
        }

//        label.text = "haha"
    }

    func displayUsername(_ stateManager: OktaOidcStateManager?) {
        
        guard let accessToken = stateManager?.authState.lastTokenResponse?.accessToken else {
            self.label.stringValue = ""
            return
        }
        
        do {
            let jwt = try decode(jwt: accessToken)
            
            self.label.stringValue = "Welcome\n\n" + (jwt.body["firstName"] as! String? ?? "") + "\n" + (jwt.body["sub"] as! String? ?? "")
        }
        catch {}
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    
    // plain browser login
    func loginCallback(stateManager: OktaOidcStateManager?, error: Error?) {
        SignInHelper.oktaOidcCallback(stateManager, error)
        displayUsername(stateManager)
    }
    func macOidcBrowserLogin() {
        oktaOidc.signInWithBrowser(redirectServerConfiguration: nil, callback: loginCallback)
    }
    
    @IBAction func login(_ sender: Any) {
        SignInHelper.doLogin(oktaOidc: oktaOidc, browserOidcLogin: macOidcBrowserLogin, successHandler: displayUsername)
    }
    
    @IBAction func logout(_ sender: Any) {
        do {
            try SignInHelper.stateManager?.removeFromSecureStorage()
        }
        catch {}
                
        self.label.stringValue = ""

        if let sm = SignInHelper.stateManager {
            oktaOidc.signOutOfOkta(authStateManager: sm) { error in
                if let error = error {
                    // Handle error
                    return
                }                
            }
        }
    }
}

