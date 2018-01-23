//
//  InterfaceController.swift
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
//import DataAccessWatch

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @objc var accAxisX: Double = 0.0
    @objc var accAxisY: Double = 0.0
    @objc var accAxisZ: Double = 0.0
    
    @objc var sleepStartDate: String = ""
    @objc var sleepEndDate: String = ""
    
    @objc var minutesPassed = 0 // if greater than 7, we start removing first element from motionOccurancesForLatest7Minutes array and appending new to the end.
    @objc var motionOccurancesCurrentMinute = 0.0
    @objc var noMotionOccurancesCurrentMinute = 0.0
    @objc var motionOccurancesForLatest7Minutes = Array(repeating: 0.0, count: 7)
    @objc var noMotionOccurancesForLatest7Minutes = Array(repeating: 0.0, count: 7)
    @objc var awakeMinutes = 0
    @objc var sleepMinutes = 0
    @objc var awakeMinutesBeforeSleep = 0
    @objc var sleepMinutesBeforeSleep = 0
    @objc var prevMinuteState = 0 // 0 means sleep, 1 means awake
    @objc var consecutiveSleepMinutes = 0 // If greater than 3, start heart rate workout monitoring.
    @objc var consecutiveAwakeMinutes = 0 // If greater than 2, stop heart rate workout monitoring.
    @objc var sleepStartDetectionThreshold = 15 // At least 'n' minutes of consecutive sleep period required.
    @objc var sleepEndDetectionThreshold = 5 // At least 'n' minutes of consecutive awake period required.
    @objc var sleepStartEndFlag = 0 // Will be 0 if sleep is detected
    
    /* Following values are not required, but can be used for more fine-grained studies in future. */
    //@objc var rotAxisX: Double = 0.0
    //@objc var rotAxisY: Double = 0.0
    //@objc var rotAxisZ: Double = 0.0
    //@objc var gravAxisX: Double = 0.0
    //@objc var gravAxisY: Double = 0.0
    //@objc var gravAxisZ: Double = 0.0
    //@objc var attAxisRoll: Double = 0.0
    //@objc var attAxisPitch: Double = 0.0
    //@objc var attAxisYaw: Double = 0.0
    
    @objc var motionDataTimeStamp: Double = 0.0
    @objc var heartRate: Double = 0.0
    @objc var previousMeanHeartRate: Double = 0.0
    @objc var heartRateCount: Double = 0.0
    @objc var heartRateTimeStamp: Double = 0.0
    
    @objc var numRecords = 0
    @objc var SendToIphoneEveryXMinutes = 1
    @objc var motionSamplingInterval = 0.2 // In seconds
    @objc var sendMotionString = ""
    
    @objc var workoutActive = false
    
    @objc var session : WCSession!
    
    @objc var watchMotionManager = CMMotionManager()
    @objc var watchMotionActivityManager = CMMotionActivityManager()
    @objc var watchInfo = WKInterfaceDevice()
    @objc var workoutSessionVar : HKWorkoutSession?
    @objc let healthStore = HKHealthStore()
    @objc var heartRatePairString = String()
    
    @objc let heartRateUnit = HKUnit(from: "count/min")
    @objc var currenQuery : HKQuery?
    
    @IBOutlet var heartRatelabel: WKInterfaceLabel!
    @IBOutlet var samplingState: WKInterfaceLabel!
    
    //interval timer (Kamran)
    @objc var intervalTimer = Timer()
    @objc var sleepMotionEventsPerMinuteTimer = Timer()
    
    //counter to count number of stop button presses (Kamran)
    @objc var stopbuttonCounter = 0;
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        watchInfo.isBatteryMonitoringEnabled = true
        
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            heartRatelabel.setText("not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            displayNotAllowed()
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                self.displayNotAllowed()
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    @IBAction func start() {
        activityTimerReset()
        stopbuttonCounter = 0
        self.startMotionDataSampling()
        samplingState.setText("Start recording")

        if(self.workoutActive == false) {
            //start a new workout
            self.workoutActive = true
            startWorkout()
        } else {
            startWorkout()
        }
    }
    
    @IBAction func stop() {
        if stopbuttonCounter == 0 {self.timerReset()}
        stopbuttonCounter += 1
        /*
         watchMotionManager.stopDeviceMotionUpdates()
         samplingState.setText("End recording")
         
         if (self.workoutActive) {
         //finish the current workout
         self.workoutActive = false
         if let workout = self.workoutSessionVar {
         healthStore.end(workout)
         }
         }
         */
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        if self.session.isReachable {
            self.setupWatchConnectivity()
        }
    }
    
    @objc func setupWatchConnectivity() {
        self.session.delegate = self
        self.session.activate()
    }
    
    @objc func activityTimerReset(){
        // A method to reset timer to 0 and start timer
        let interval:TimeInterval = 60.0
        //Control the timer control on the interface
        //let time  = Date(timeIntervalSinceNow: interval)
        
        //control the runLoop timer
        if intervalTimer.isValid {activityTimerStop()} //shut off timer if on
        sleepMotionEventsPerMinuteTimer = Timer.scheduledTimer(timeInterval: interval ,
                                             target: self,  //Object to target when done
            selector: #selector(self.activityTimerDidEnd(timer:)), //Method on the object
            userInfo: nil, //Extra user info, most likely a dictionary
            repeats: true) //Repeat of not
        
    }
    
    @objc func activityTimerStop(){
        sleepMotionEventsPerMinuteTimer.invalidate()
    }
    
    @objc func activityTimerDidEnd(timer:Timer){
        print(motionOccurancesCurrentMinute, "<----One minute passed!")
        
        switch watchInfo.batteryState {
        case .unplugged:
            if minutesPassed == 7 { // Start detecting active and sleep minutes after 7 minutes have passed.
                
                let D = (0.18 * (0.15 * motionOccurancesForLatest7Minutes[0] + 0.15 * motionOccurancesForLatest7Minutes[1] + 0.15 * motionOccurancesForLatest7Minutes[2] + 0.08 * motionOccurancesForLatest7Minutes[3] +
                    0.21 * motionOccurancesForLatest7Minutes[4] + 0.12 * motionOccurancesForLatest7Minutes[5] + 0.13 * motionOccurancesForLatest7Minutes[6]))
                
                if D > 1.0 {
                    awakeMinutes += 1
                    if (prevMinuteState == 1) {
                        consecutiveAwakeMinutes += 1
                    } else {
                        consecutiveAwakeMinutes = 1
                        consecutiveSleepMinutes = 0
                        prevMinuteState = 1
                    }
                } else {
                    sleepMinutes += 1
                    if (prevMinuteState == 0) {
                        consecutiveSleepMinutes += 1
                    } else {
                        consecutiveSleepMinutes = 1
                        consecutiveAwakeMinutes = 0
                        prevMinuteState = 0
                    }
                }
                
                /*
                 // Heart rate will be updated every 5 minutes for 2 minutes when rest period is detected.
                 // If person active more than one minute, we stop heart rate monitoring.
                 if (consecutiveSleepMinutes > 0 && consecutiveSleepMinutes % 5 == 0) {
                 print("heartRate started")
                 if(self.workoutActive == false) {
                 //start a new workout
                 self.workoutActive = true
                 startWorkout()
                 } else{
                 startWorkout()
                 }
                 } else if (consecutiveAwakeMinutes > 1 || consecutiveSleepMinutes % 5 > 1) {
                 print("heartRate stopped")
                 if (self.workoutActive) {
                 //finish the current workout
                 self.workoutActive = false
                 if let workout = self.workoutSessionVar {
                 healthStore.end(workout)
                 }
                 }
                 }
                 */
                
                // Heart rate will be updated every 2 minutes to save battery.
                if ((awakeMinutes + sleepMinutes) > 0 && (awakeMinutes + sleepMinutes) % 5 == 0) {
                    if (self.workoutActive) {
                        if let workout = self.workoutSessionVar {
                            healthStore.resumeWorkoutSession(workout)
                        }
                    }
                } else {
                    if (self.workoutActive) {
                        if let workout = self.workoutSessionVar {
                            healthStore.pause(workout)
                        }
                    }
                }
                
                motionOccurancesForLatest7Minutes.remove(at: 0)
                noMotionOccurancesForLatest7Minutes.remove(at: 0)
                motionOccurancesForLatest7Minutes.append(motionOccurancesCurrentMinute * motionSamplingInterval)
                noMotionOccurancesForLatest7Minutes.append(noMotionOccurancesCurrentMinute * motionSamplingInterval)
                
                //motionDataTimeStamp = Date().timeIntervalSince1970 * 1000  // assign double value so the timestamp should be double
                //sendMotionString = sendMotionString + String(rotAxisX) + "," + String(rotAxisY) + "," + String(rotAxisZ)
                //sendMotionString = sendMotionString + "," + String(accAxisX) + "," + String(accAxisY) + "," + String(accAxisZ)
                //sendMotionString = sendMotionString + "," + String(attAxisRoll) + "," + String(attAxisPitch) + "," + String(attAxisYaw)
                //sendMotionString = sendMotionString + "," + String(gravAxisX) + "," + String(gravAxisY) + "," + String(gravAxisZ)
                //sendMotionString = sendMotionString + "," + String(motionDataTimeStamp) + "," + String(heartRate) + "," + String(heartRateTimeStamp) + "\n"
                
                //sendMotionString = sendMotionString + String(motionOccurancesCurrentMinute * motionSamplingInterval) + "," + String(noMotionOccurancesCurrentMinute * motionSamplingInterval)
                //sendMotionString = sendMotionString + "," + String(heartRate) + "," + String(heartRateTimeStamp)
                sendMotionString = sendMotionString + String(Double(round(100 * heartRate)/100)) // Heart rate here is the average heart rate as calculated in HeartRate.swift
                
                if (consecutiveSleepMinutes >= sleepStartDetectionThreshold && sleepStartEndFlag == 0) {
                    sleepMinutesBeforeSleep = sleepMinutes
                    awakeMinutesBeforeSleep = awakeMinutes
                    sleepStartEndFlag = 1
                    sleepStartDate = getCurrentDateMonth()
                    sendMotionString = sendMotionString + "," + String(sleepMinutes) + "," + String(awakeMinutes) + "," + String(consecutiveSleepMinutes) + "," + String(consecutiveAwakeMinutes) + "," + String(sleepStartEndFlag) + ",0," + getCurrentDateMonth() + "," + String(watchInfo.batteryLevel) + "\n"
                } else if (consecutiveAwakeMinutes >= sleepEndDetectionThreshold && sleepStartEndFlag == 1) {
                    sleepStartEndFlag = 0
                    sleepEndDate = getCurrentDateMonth()
                    var score: Double = Double(sleepMinutes) - Double(sleepMinutesBeforeSleep)
                    score = score/Double((awakeMinutes-sleepEndDetectionThreshold) + sleepMinutes - awakeMinutesBeforeSleep - (sleepMinutesBeforeSleep - sleepStartDetectionThreshold))
                    sendMotionString = sendMotionString + "," + String(sleepMinutes) + "," + String(awakeMinutes) + "," + String(consecutiveSleepMinutes) + "," + String(consecutiveAwakeMinutes) + "," + String(sleepStartEndFlag)
                    sendMotionString = sendMotionString + "," + String(Double(round(1000 * score)/1000)) + "," + getCurrentDateMonth() + "," + String(watchInfo.batteryLevel) + "\n"
                    
                    let sendSleepString = "Sleep Started: " + sleepStartDate + "\n" + "Sleep Ended: " + sleepEndDate
                    let stringSend = ["sleepString": sendSleepString]
                    self.sendStringToIphone(applicationStr: stringSend)
                    
                } else {
                    sendMotionString = sendMotionString + "," + String(sleepMinutes) + "," + String(awakeMinutes) + "," + String(consecutiveSleepMinutes) + "," + String(consecutiveAwakeMinutes) + "," + String(sleepStartEndFlag) + ",0," + getCurrentDateMonth() + "," + String(watchInfo.batteryLevel) + "\n"
                }
                
                if numRecords % SendToIphoneEveryXMinutes == 0 {
                    //print(sendMotionString, " <---")
                    let stringSend = ["TestString": sendMotionString]
                    self.sendStringToIphone(applicationStr: stringSend)
                    
                    //print(sendMotionString,"    <---")
                    sendMotionString =  ""    // Reset string.
                }
                numRecords += 1
                
            } else {
                motionOccurancesForLatest7Minutes[minutesPassed]  = motionOccurancesCurrentMinute * motionSamplingInterval
                noMotionOccurancesForLatest7Minutes[minutesPassed] = motionOccurancesCurrentMinute * motionSamplingInterval
                minutesPassed += 1
                
                //motionOccurancesForLatest7Minutes.append(motionOccurancesCurrentMinute * motionSamplingInterval)
                //noMotionOccurancesForLatest7Minutes.append(noMotionOccurancesCurrentMinute * motionSamplingInterval)
            }
        default:
            minutesPassed = 0
            sleepMinutes = 0
            awakeMinutes = 0
            consecutiveSleepMinutes = 0
            consecutiveAwakeMinutes = 0
            sendMotionString = String(0) + "," + String(0) + "," + String(0) + "," + String(0) + "," + String(0) + "," + String(0) + ",0," + getCurrentDateMonth() + "," + "-1" + "\n"
            let stringSend = ["TestString": sendMotionString]
            self.sendStringToIphone(applicationStr: stringSend)
            sendMotionString =  ""    // Reset string.
        }
        
        motionOccurancesCurrentMinute = 0
        heartRateCount = 0 // It is used to calculate running average heart rate over multiple readings accumulated over a minute.
        // It is Reset at the end of each minute.
    }
    
    @objc func timerReset(){
        // A method to reset timer to 0 and start timer
        let interval:TimeInterval = 1.0
        //Control the timer control on the interface
        //let time  = Date(timeIntervalSinceNow: interval)
        
        //control the runLoop timer
        if intervalTimer.isValid {timerStop()} //shut off timer if on
        intervalTimer = Timer.scheduledTimer(timeInterval: interval ,
                                             target: self,  //Object to target when done
            selector: #selector(self.timerDidEnd(timer:)), //Method on the object
            userInfo: nil, //Extra user info, most likely a dictionary
            repeats: false) //Repeat of not
        
    }
    
    @objc func timerStop(){
        intervalTimer.invalidate()
    }
    
    
    @objc func timerDidEnd(timer:Timer){
        print(stopbuttonCounter,"<----Button Press Count")
        
        //When we reach end of an workout interval, switch workout type
        if (stopbuttonCounter >= 5){
            watchMotionManager.stopDeviceMotionUpdates()
            watchMotionActivityManager.stopActivityUpdates()
            samplingState.setText("End recording")
            
            if (self.workoutActive) {
                //finish the current workout
                self.workoutActive = false
                if let workout = self.workoutSessionVar {
                    healthStore.end(workout)
                }
            }
            timerStop()
        }
        else {
            timerReset()
        }
        
        stopbuttonCounter = 0
    }
    
    @objc func getCurrentDateMonth() -> String {
        
        let date = Date()
        // "Jul 23, 2014, 11:01 AM" <-- looks local without seconds. But:
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d-MMM-yyyy, h:mm a"
        let defaultTimeZoneStr = formatter.string(from: date)
        
        /* Other date formats */
        // "2014-07-23 11:01:35 -0700" <-- same date, local, but with seconds
        // formatter.timeZone = TimeZone(abbreviation: "UTC")
        // let utcTimeZoneStr = formatter.string(from: date)
        // "2014-07-23 18:01:41 +0000" <-- same date, now in UTC
        
        return defaultTimeZoneStr;
        
    }
}
