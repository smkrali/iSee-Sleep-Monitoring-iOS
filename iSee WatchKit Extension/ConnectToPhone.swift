//
//  ConnectToPhone.swift
//  iSee WatchKit Extension
//
//  Created by Kamran Ali on 10/21/17.
//  Copyright © 2017 KamranAliMSU. All rights reserved.
//

import WatchKit
import UIKit
import Foundation
import CoreMotion
import CoreData
import WatchConnectivity
import HealthKit
import WatchKit
//import DataAccessWatch

extension InterfaceController {
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activationDidCompleteWith failed with error: \(error.localizedDescription)")
            return    }
    }
    
    @objc func sendStringToIphone(applicationStr: [String : Any]) -> Void{
        session.sendMessage(applicationStr,
                            replyHandler:  { (replyDict) -> Void in
                                print(replyDict)
        }, errorHandler:{ error in
            print(error)
        })
    }
}

