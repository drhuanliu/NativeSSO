//
//  ViewController.swift
//  NativeSSO
//
//  Created by Huan Liu on 7/29/21.
//

import UIKit
import OktaOidc
import JWTDecode

class ViewController: UIViewController {

    var oktaOidc : OktaOidc!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        do {
            let configuration = try OktaOidcConfig(with: [
                "issuer": SignInHelper.issuer,
                "clientId": "0oa826j5pHmPRt2n00w6",
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
        
    }
    
    func displayUsername(_ stateManager: OktaOidcStateManager?) {
        
        guard let accessToken = stateManager?.authState.lastTokenResponse?.accessToken else {
            self.label.text = ""
            return
        }
        
        do {
            let jwt = try decode(jwt: accessToken)
            
            self.label.text = "Welcome\n\n" + (jwt.body["firstName"] as! String? ?? "") + "\n" + (jwt.body["sub"] as! String? ?? "")
            print(jwt.body)
        }
        catch {}
    }

    func refreshToken() {
        SignInHelper.stateManager?.authState.setNeedsTokenRefresh()
        SignInHelper.stateManager?.authState.performAction(freshTokens: { accessToken, idToken, error in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
        })

    }
    
    func loginCallback(stateManager: OktaOidcStateManager?, error: Error?) {
        SignInHelper.oktaOidcCallback(stateManager, error)
        displayUsername(stateManager)
    }
    // plain browser login
    func iosOidcBrowserLogin() {
        oktaOidc.signInWithBrowser(from: self, callback: loginCallback)
    }
    
    @IBAction func login(_ sender: Any) {
        SignInHelper.doLogin(oktaOidc: oktaOidc, browserOidcLogin: iosOidcBrowserLogin, successHandler: displayUsername )
    }
    
    @IBAction func logout(_ sender: Any) {
        do {
            try SignInHelper.stateManager?.removeFromSecureStorage()
        }
        catch {}
        
        self.label.text = ""

        if let sm = SignInHelper.stateManager {
            oktaOidc.signOutOfOkta(sm, from: self) { error in
                if let error = error {
                    // Handle error
                    return
                }
            }
        }
    }

        
}

