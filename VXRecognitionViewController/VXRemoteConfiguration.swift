//
//  RemoteConfiguration.swift
//  species
//
//  Created by Graham Lancashire on 14.06.19.
//  Copyright © 2019 Swift Management AG. All rights reserved.
//

import Foundation
import Firebase

public enum VXRemoteConfigurationKeys: String {
    case detection_model
    case detection_threshold
}

public class VXRemoteConfiguration {
    static let shared = VXRemoteConfiguration()

    private init(){
        debugPrint("VXRemoteConfiguration: initialising")
        RemoteConfig.remoteConfig().configSettings = RemoteConfigSettings()
        
        // set debug mode if needed
        if Config.isDebug == true  {
            debugPrint("VXRemoteConfiguration: setting debug mode")
        }
        
        // load defaults from bundle
        loadDefaults()
        
        // load current values from cloud
        loadCloud()
    }

    // load defaults from bundle
    func loadDefaults() {
        // check we if have a config plist file
        if let path = Bundle.main.path(forResource: "RemoteConfigDefaults", ofType: "plist") {
            // load defaults from plist
            RemoteConfig.remoteConfig().setDefaults(fromPlist: "RemoteConfigDefaults")
            debugPrint("VXRemoteConfiguration: setting defaults with \(path). ")
        }
    }
    
    
    // load current values from cloud
    func loadCloud() {
        // define validity (default 12h)
        //let expirationDuration: TimeInterval = Config.isDebug ? 0 : (12 * 60 * 60)
        
        // fetch values from firebase
        RemoteConfig.remoteConfig().fetchAndActivate(completionHandler: { (status, error) in
            // check for error
            if let error = error {
                print("VXRemoteConfiguration: error fetching remote values \(error)")
                return
            } else {
                debugPrint("VXRemoteConfiguration: activated values from the cloud \(status). ")
            }
        })
    }
    
    public func string(forKey key: VXRemoteConfigurationKeys) -> String {
            let value = RemoteConfig.remoteConfig()[key.rawValue].stringValue ?? ""
        
        debugPrint("VXRemoteConfiguration: retrieved string from the cloud \(key) -> \(value). ")
        return value
    }
    public func number(forKey key: VXRemoteConfigurationKeys) -> NSNumber {
        let value = RemoteConfig.remoteConfig()[key.rawValue].numberValue ?? 0.0
        
        debugPrint("VXRemoteConfiguration: retrieved number from the cloud \(key) -> \(value). ")
        return value
    }
}
