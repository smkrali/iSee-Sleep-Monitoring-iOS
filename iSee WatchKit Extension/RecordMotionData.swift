//
//  RecordMotionData.swift
//  iSee WatchKit Extension
//
//  Created by Kamran Ali on 10/21/17.
//  Copyright © 2017 KamranAliMSU. All rights reserved.
//

import Foundation
import WatchKit
import UIKit
import Foundation
import CoreMotion
import WatchConnectivity
import Accelerate

extension InterfaceController {
    
    
    @objc func startMotionDataSampling() {
        
        if(self.workoutActive == false) {
            //start a new workout
            self.workoutActive = true
        }
        
        /*
        if CMMotionActivityManager.isActivityAvailable() {
            self.watchMotionActivityManager.startActivityUpdates(to: OperationQueue.current!, withHandler: { (data: CMMotionActivity!) in
                if data.stationary == false {self.motionOccurancesCurrentMinute += 1}
            })
        }
        */
        
        watchMotionManager.deviceMotionUpdateInterval = motionSamplingInterval // Sampling Rate doesn't have to be too high for this application, as we are not detecting any fine grained pattern.
        
        if watchMotionManager.isDeviceMotionAvailable {  // Device motion
            
            watchMotionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (deviceManager: CMDeviceMotion?, error) in
                self.outputWatchMotionData(watchMotion: deviceManager!)  //Start updating motion data.
                
                if (error != nil){
                    
                    print("Error!")
                }
                
            })
            
        } else {
            
            print("Motion device not available")
        }
        
    }
    
    
    @objc func outputWatchMotionData(watchMotion: CMDeviceMotion){
        
        let tempXacc: Double  = (watchMotion.userAcceleration.x)
        let tempYacc: Double = (watchMotion.userAcceleration.y)
        let tempZacc: Double = (watchMotion.userAcceleration.z)
        
        accAxisX = tempXacc - accAxisX
        accAxisY = tempYacc - accAxisY
        accAxisZ = tempZacc - accAxisZ
        
        /* Following values are not required, but can be used for more fine-grained studies in future. */
        //rotAxisX = (watchMotion.rotationRate.x)
        //rotAxisY = (watchMotion.rotationRate.y)
        //rotAxisZ = (watchMotion.rotationRate.z)
        //attAxisRoll = (watchMotion.attitude.roll)
        //attAxisYaw = (watchMotion.attitude.yaw)
        //attAxisPitch = (watchMotion.attitude.pitch)
        //gravAxisX = (watchMotion.gravity.x)
        //gravAxisY = (watchMotion.gravity.y)
        //gravAxisZ = (watchMotion.gravity.z)
        
        if (abs(accAxisX + accAxisY + accAxisZ) > 3*0.02) {
            motionOccurancesCurrentMinute += 1
        } else {
            noMotionOccurancesCurrentMinute += 1
        }
        
        accAxisX = tempXacc
        accAxisY = tempYacc
        accAxisZ = tempZacc
    
    }
    
    
}

