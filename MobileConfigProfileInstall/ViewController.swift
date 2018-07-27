//
//  ViewController.swift
//  MobileConfigProfileInstall
//
//  Created by Andrian Sergheev on 7/27/18.
//  Copyright © 2018 Andrian Sergheev. All rights reserved.
//

import UIKit
import Swifter

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    
    //MARK: VPN state.
    var isVpnEnabled : Bool = false
    
    
    
    
    
    
    //MARK: Outlets
    @IBOutlet weak var vpnButtonLabel: UIButton!
    
    @IBAction func vpnButton(_ sender: Any) {
        
        if isVpnEnabled == true {
            (sender as? UIButton)?.setTitle("Install profile", for: [])
            setupVPN()
            
        } else {
            (sender as? UIButton)?.setTitle("Disable VPN", for: [])
            setupVPN()
        }
    }
    
    
    
    
    
    
    let confURL = Bundle.main.path(forResource: "config", ofType: "mobileconfig")
    var dataInfo : Data?
    
    
    
    
    
    
    
    
    
    //MARK: Logic
    func setupVPN() {
        let confFile:URL = URL.init(fileURLWithPath: confURL!)
        do {
            let confData = try Data(contentsOf: confFile as URL)
            self.dataInfo = confData
        } catch {
            print("Unable to load data: \(error)")
        }
        
        //MARK: Initialization
        let initVPN = Config.init(configData: self.dataInfo!, returnURL: "myAppURLScheme")
        
        if isVpnEnabled == false {
            if Config.start(initVPN)() == true {
                isVpnEnabled = !isVpnEnabled
                print("Loaded")
            }
        } else if isVpnEnabled == true {
            Config.stop(initVPN)()
            print("Stoped")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
