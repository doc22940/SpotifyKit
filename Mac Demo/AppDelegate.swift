//
//  AppDelegate.swift
//  Mac Demo
//
//  Created by Marco Albera on 16/09/2017.
//

import Cocoa
import Swiftify
import Alamofire

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    let swiftify = SwiftifyHelper(with:
        SwiftifyHelper.SpotifyDeveloperApplication(
            clientId:     "64961bd35af24dd4862ae29e0a8f5caa",
            clientSecret: "8d6ec5ba180b4114b4212bcd618bf6ad",
            redirectUri:  "swiftifymac://callback"
        )
    )
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initEventManager()
        
        loadSwiftify()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            self.find(SpotifyTrack.self, "concrete heartbeat")
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) { }
    
    func loadSwiftify() {
        if !swiftify.hasToken {
            // Try to authenticate if there's no token
            swiftify.authorize()
        } else {
            // Refresh the token if present
            swiftify.refreshToken { refreshed in }
        }
    }
    
    // MARK: URL handling
    
    func initEventManager() {
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(handleURLEvent),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }
    
    /**
     Catches URLs with specific prefix ("muse://")
     */
    @objc func handleURLEvent(event: NSAppleEventDescriptor,
                              replyEvent: NSAppleEventDescriptor) {
        if  let urlDescriptor = event.paramDescriptor(forKeyword: keyDirectObject),
            let urlString     = urlDescriptor.stringValue,
            let urlComponents = URLComponents(string: urlString),
            let queryItems    = urlComponents.queryItems {
            
            // Get "code=" parameter from URL
            // https://gist.github.com/gillesdemey/509bb8a1a8c576ea215a
            let code = queryItems.filter { item in item.name == "code" } .first?.value!
                        
            // Send code to Swiftify
            if let authorizationCode = code {
                swiftify.saveToken(from: authorizationCode)
            }
        }
    }
    
    // MARK: Swiftify features implementation
    
    func find<T>(_ type: T.Type, _ keyword: String) where T: SpotifyItem {
        swiftify.find(type, keyword) { result in
            print(result)
        }
    }
    
}

