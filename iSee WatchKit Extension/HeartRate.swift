//
//  HeartRate.swift
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

extension InterfaceController: HKWorkoutSessionDelegate {
    
    @objc func displayNotAllowed() {
        heartRatelabel.setText("not allowed")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
            print("heartRate resumed!")
        case .ended:
            workoutDidEnd(date)
        case .paused:
            healthStore.stop(self.currenQuery!)
            heartRatelabel.setText("---")
            print("heartRate paused!")
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        print("Workout error")
    }
    
    
    @objc func workoutDidStart(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            self.currenQuery = query
            healthStore.execute(query)
        } else {
            heartRatelabel.setText("cannot start")
        }
    }
    
    @objc func workoutDidEnd(_ date : Date) {
        healthStore.stop(self.currenQuery!)
        heartRatelabel.setText("---")
        workoutSessionVar = nil
    }
    
    // MARK: - Actions
    
    @objc func startWorkout() {
        
        // If we have already started the workout, then do nothing.
        if (workoutSessionVar != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .mindAndBody
        workoutConfiguration.locationType = .indoor
        
        do {
            workoutSessionVar = try HKWorkoutSession(configuration: workoutConfiguration)
            workoutSessionVar?.delegate = self
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        healthStore.start(self.workoutSessionVar!)
    }
    
    @objc func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //guard let newAnchor = newAnchor else {return}
            //self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    @objc func updateHeartRate(_ samples: [HKSample]?) {
        
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        DispatchQueue.main.sync {
            guard let sample = heartRateSamples.first else { return }
            var value = sample.quantity.doubleValue(for: self.heartRateUnit)
            value = Double(value)
            
            self.heartRatelabel.setText(String(UInt16(value)))
            //print(value,"  <----show me lable")
            
            // retrieve source from sample
            _ = sample.sourceRevision.source.name
            //self.updateDeviceName(name)
            //self.animateHeart()
            
            heartRate = (heartRateCount * previousMeanHeartRate + value) / (heartRateCount + 1)
            previousMeanHeartRate = heartRate
            heartRateCount = heartRateCount + 1
            
            heartRateTimeStamp = Date().timeIntervalSince1970
            //self.appendAndSendHeartRateString(heartRateValue: String(heartRate), timeStamp: String(timeStamp))
            //print(healthData.heartRate, "<------in CoreData")
            //print(heartRateTimeStamp, "<------time stamp")
        }
    }
}
