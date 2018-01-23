//
//  ConnectWithWatch.swift
//  iSee
//
//  Created by Kamran Ali on 10/28/17.
//  Copyright © 2017 KamranAliMSU. All rights reserved.
//

import UIKit
import WatchConnectivity

extension ViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WC Session activation failed with error: \(error.localizedDescription)")
            return    }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession){
        print("session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession){
        print("session did deactivate")
        
    }
    
    // This is where the messages are received from the iWatch.
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        DispatchQueue.main.async { [weak self] in
            if let messageString = message["TestString"] as! String! {
                self?.receiveTextField.text = messageString
                self?.writeToCSV.saveToCSV(dataStr: messageString)
                //self.writeToCSV.testRetriveData()
            }
            
            if let sleepString = message["sleepString"] as! String! {
                self?.sleepInfoTextField.text = "Last Sleep Information \n" + sleepString
            }
        }
        
        replyHandler(["Value":"Yes"])
        
    }
}

