//
//  ViewController.swift
//  iSee
//
//  Created by Kamran Ali on 10/21/17.
//  Copyright © 2017 KamranAliMSU. All rights reserved.
//

import UIKit
import MessageUI
import WatchConnectivity
import HealthKit
import SwiftyDropbox

class ViewController: UIViewController {

    @IBOutlet weak var receiveTextField: UITextView!
    @IBOutlet weak var uploadProgressBar: UIProgressView!
    @IBOutlet weak var dropboxConnection: UIButton!
    @IBOutlet weak var sleepInfoTextField: UITextView!
    
    @objc var attachmentFilePath:URL?
    @objc let session = WCSession.default
    @objc let healthStore = HKHealthStore()
    
    @objc let writeToCSV = WriteToCSV()
    @objc var heartRateString = String()
    
    @objc func fileExistance()->Bool {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let surveys = NSURL(fileURLWithPath: docPath).appendingPathComponent("results.csv")
        let surveysfilepath = surveys?.path
        
        if (FileManager.default.fileExists(atPath: surveysfilepath!)) {
            print("File Available")
            return true
        }else{
            print("File NOT Available")
            return false
        }
    }
    
    @objc func getFilePath() -> String {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let docsDir = NSURL(fileURLWithPath: docPath).appendingPathComponent("results.csv")
        let surveysfilepath = docsDir?.path
        let filePath = surveysfilepath
        return filePath!
        
    }
    
    @objc func resetAppDataFunc() {
        hiddenProgressBar()
        if fileExistance() {
            let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let surveys = NSURL(fileURLWithPath: docPath).appendingPathComponent("results.csv")
            let surveysfilepath = surveys?.path
            if (FileManager.default.fileExists(atPath: surveysfilepath!)) {
                print("It has file ")
                do{
                    try FileManager.default.removeItem(atPath: surveysfilepath!)
                }catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
                
            }
        }
        receiveTextField.text = "Incoming Data From iWatch"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Uncommenting as it can lead to a reset of data. Reset when the user presses start on the iWatch app.
        // resetAppDataFunc()
        
        // Watch Connectivity possible.
        if WCSession.isSupported() {
            print("Can get to the iWatch!")
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        hiddenProgressBar()
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
            }
        }
    }
    
    @IBAction func resetAppData(_ sender: Any) {
        resetAppDataFunc()
    }
    
    @IBAction func connectoToDropbox(_ sender: UIButton) {
       
        DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                      controller: self,
                                                      openURL: { (url: URL) -> Void in
                                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
        
    }
    
    @IBAction func sendToDropbox(_ sender: UIButton) {
        hiddenProgressBar()
        
        if fileExistance() {
            let filep = getFilePath()
        
            if let client = DropboxClientsManager.authorizedClient {
                let currentDate = getCurrentDateMonth()
                let deviceID = UIDevice.current.identifierForVendor!.uuidString
                let uploadFilename = "/Apps/SleepDataRecordFolder/" + deviceID + "  \(currentDate)" + ".csv"
                showProgressBar()
                print("Yes")
                client.files.upload(path: uploadFilename, input: URL(fileURLWithPath: filep)).progress({ [weak self] (progressVal) in
                    if progressVal.isFinished {
                        self?.uploadingProgress(value: 1.0)
                        //resetAppDataFunc()
                    }
                })
            }
        }
    }
    
    func uploadingProgress(value: Float) {
        uploadProgressBar.isHidden = false
        uploadProgressBar.setProgress(value, animated: true)
    }
    
    func hiddenProgressBar() {
        uploadingProgress(value: 0.0)
        uploadProgressBar.isHidden = true
    }
    
    @objc func showProgressBar() {
        uploadingProgress(value: 0.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func getCurrentDateMonth() -> String {
        
        let date = Date()
        // "Jul 23, 2014, 11:01 AM" <-- looks local without seconds. But:
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss ZZZ"
        let defaultTimeZoneStr = formatter.string(from: date)
        
        /* Other date formats */
        // "2014-07-23 11:01:35 -0700" <-- same date, local, but with seconds
        // formatter.timeZone = TimeZone(abbreviation: "UTC")
        // let utcTimeZoneStr = formatter.string(from: date)
        // "2014-07-23 18:01:41 +0000" <-- same date, now in UTC
        
        return defaultTimeZoneStr;
        
    }
}

