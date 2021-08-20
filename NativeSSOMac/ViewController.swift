//
//  ViewController.swift
//  NativeSSOMac
//
//  Created by Huan Liu on 8/14/21.
//

import Cocoa
import OktaOidc

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

            displayUsername()
        }
        catch {
            print(error)
        }

//        label.text = "haha"
    }

    func displayUsername() {
        SignInHelper.stateManager?.getUser { response, error in
            if let error = error {
                // Error
                return
            }

            // response is Dictionary - [String:Any]
//            let firsname = response?["firstName"] as? String
//            let sub = response?["sub"] as? String
//            self.label.text = (firsname ?? "") + "\n" + (sub ?? "")
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func macOidcBrowserLogin() {
        oktaOidc.signInWithBrowser(redirectServerConfiguration: nil, callback: SignInHelper.oktaOidcCallback)
    }
    
    @IBAction func login(_ sender: Any) {
        SignInHelper.doLogin(oktaOidc: oktaOidc, browserOidcLogin: macOidcBrowserLogin )
    }
    
    @IBAction func logout(_ sender: Any) {
        if let sm = SignInHelper.stateManager {
            oktaOidc.signOutOfOkta(authStateManager: sm) { error in
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
        SignInHelper.removeDeviceSecret()
    }
}

