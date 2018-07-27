//
//  Config.swift
//  MobileConfigProfileInstall
//
//  Created by Andrian Sergheev on 7/27/18.
//  Copyright © 2018 Andrian Sergheev. All rights reserved.
//

import Foundation

import UIKit
import Swifter

class Config : NSObject {
    
    //TODO: Don't foget to add your custom app url scheme to info.plist if you have one!
    
    private enum ConfigState: Int
    {
        case Stopped, Ready, InstalledConfig, BackToApp
    }
    
    
    
    internal let listeningPort: in_port_t! = 8080
    internal var configName: String! = "Profile install"
    private var localServer: HttpServer!
    private var returnURL: String!
    private var configData: Data!
    
    private var serverState: ConfigState = .Stopped
    private var startTime: NSDate!
    private var registeredForNotifications = false
    private var backgroundTask = UIBackgroundTaskInvalid
    
    deinit
    {
        unregisterFromNotifications()
    }
    
    init(configData: Data, returnURL: String)
    {
        super.init()
        self.returnURL = returnURL
        self.configData = configData
        localServer = HttpServer()
        self.setupHandlers()
    }
    
    //MARK:- Control functions
    
    internal func start() -> Bool
    {
        let page = self.baseURL(pathComponent: "start/")
        let url = URL(string: page)!
        if UIApplication.shared.canOpenURL(url as URL) {
            do {
                try localServer.start(listeningPort, forceIPv4: false, priority: .default)
                
                startTime = NSDate()
                serverState = .Ready
                registerForNotifications()
                UIApplication.shared.openURL(url)
                return true
            } catch {
                self.stop()
            }
        }
        return false
    }
    
    internal func stop()
    {
        if serverState != .Stopped {
            serverState = .Stopped
            unregisterFromNotifications()
        }
    }
    
    //MARK:- Private functions
    
    private func setupHandlers()
    {
        localServer["/start"] = { request in
            if self.serverState == .Ready {
                let page = self.basePage(pathComponent: "install/")
                return .ok(.html(page))
            } else {
                return .notFound
            }
        }
        localServer["/install"] = { request in
            switch self.serverState {
            case .Stopped:
                return .notFound
            case .Ready:
                self.serverState = .InstalledConfig
                return HttpResponse.raw(200, "OK", ["Content-Type": "application/x-apple-aspen-config"], { writer in
                    do {
                        try writer.write(self.configData)
                    } catch {
                        NSLog("Failed to write response data")
                    }
                })
            case .InstalledConfig:
                return .movedPermanently(self.returnURL)
            case .BackToApp:
                let page = self.basePage(pathComponent: nil)
                return .ok(.html(page))
            }
        }
    }
    
    private func baseURL(pathComponent: String?) -> String
    {
        var page = "http://localhost:\(listeningPort!)"
        if let component = pathComponent {
            page += "/\(component)"
        }
        return page
    }
    
    private func basePage(pathComponent: String?) -> String
    {
        var page = "<!doctype html><html>" + "<head><meta charset='utf-8'><title>\(self.configName!)</title></head>"
        if let component = pathComponent {
            let script = "function load() {  window.location.href='\(self.baseURL(pathComponent: component))'; }window.setInterval(load, 800);"
            
            page += "<script>\(script)</script>"
        }
        page += "<body></body></html>"
        return page
    }
    
    
    
    
    
    
    
    
    
    
    
    
    private func returnedToApp() {
        if serverState != .Stopped {
            serverState = .BackToApp
            localServer.stop()
        }
        // Do whatever else you need to to
    }
    
    private func registerForNotifications() {
        if !registeredForNotifications {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            notificationCenter.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
            registeredForNotifications = true
        }
    }
    
    private func unregisterFromNotifications() {
        if registeredForNotifications {
            let notificationCenter = NotificationCenter.default
            notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            notificationCenter.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
            registeredForNotifications = false
        }
    }
    
    @objc internal func didEnterBackground(notification: NSNotification) {
        if serverState != .Stopped {
            startBackgroundTask()
        }
    }
    
    @objc internal func willEnterForeground(notification: NSNotification) {
        if backgroundTask != UIBackgroundTaskInvalid {
            stopBackgroundTask()
            returnedToApp()
        }
    }
    
    private func startBackgroundTask() {
        let application = UIApplication.shared
        backgroundTask = application.beginBackgroundTask(expirationHandler: {
            DispatchQueue.main.async {
                self.stopBackgroundTask()
            }
        })
    }
    
    private func stopBackgroundTask() {
        if backgroundTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }
    
    
    
}







