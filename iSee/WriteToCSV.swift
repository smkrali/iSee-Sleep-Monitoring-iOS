//
//  WriteToCSV.swift
//  iSee
//
//  Created by Kamran Ali on 10/28/17.
//  Copyright © 2017 KamranAliMSU. All rights reserved.
//

import Foundation
import UIKit

class WriteToCSV: NSObject{
    @objc func saveToCSV(dataStr:String) -> Void{
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let surveys = NSURL(fileURLWithPath: docPath).appendingPathComponent("results.csv")
        let surveysfilepath = surveys?.path
        
        
        if (FileManager.default.fileExists(atPath:surveysfilepath!)){
            if let fileHandle = FileHandle(forWritingAtPath: surveysfilepath!) {
                let data = dataStr.data(using: .utf8, allowLossyConversion: true)
                
                fileHandle.seekToEndOfFile()
                fileHandle.write(data!)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        } else {
            FileManager.default.createFile(atPath: surveysfilepath!, contents: nil, attributes: nil)
            if let fileHandle = FileHandle(forWritingAtPath: surveysfilepath!) {
                let data = dataStr.data(using: .utf8, allowLossyConversion: true)
                
                fileHandle.seekToEndOfFile()
                fileHandle.write(data!)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        }
        
    }
}

