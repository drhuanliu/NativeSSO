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

            displayUsername()
        }
        catch {
            print(error)
        }
        
    }
    
    func displayUsername() {
        SignInHelper.stateManager?.getUser { response, error in
            if let error = error {
                // Error
                return
            }

            // response is Dictionary - [String:Any]
            let firsname = response?["firstName"] as? String
            let sub = response?["sub"] as? String
            self.label.text = (firsname ?? "") + "\n" + (sub ?? "")
        }
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

    func iosOidcBrowserLogin() {
        oktaOidc.signInWithBrowser(from: self, callback: SignInHelper.oktaOidcCallback)
    }
    
    @IBAction func login(_ sender: Any) {
        SignInHelper.doLogin(oktaOidc: oktaOidc, browserOidcLogin: iosOidcBrowserLogin )
        
        displayUsername()
    }
    
    @IBAction func logout(_ sender: Any) {
        oktaOidc.signOutOfOkta(SignInHelper.stateManager!, from: self) { error in
            if let error = error {
                // Handle error
                return
            }
            
            do {
                try SignInHelper.stateManager?.removeFromSecureStorage()
            }
            catch {}
        }
    }

        
}

