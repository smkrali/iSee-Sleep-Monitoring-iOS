# iSee-Sleep-Monitoring-iOS

iOS Development Related : Sleep Monitoring

A zip-file of the complete project is uploaded on Dropbox (compiled for latest WatchOS 4.2 and iOS 11 updates). 
Link: https://www.dropbox.com/s/jv4ken11ta9z8ck/iSee.zip?dl=0

1. Changed some files in Swix to make it compatible for WatchOS 4.2 and iOS 11.
2. OpenCV - Download the git repository. Build it for iOS. All other logs/notes are in the opencv.mm file. Basically, we have to make everything compatible with OpenCV which is compiled with Objective-C++ libraries and iOS/Watch libraries which are Objective-C as base, and on top Swift.
3. Disable Documentation Comments in Build Phases in project settings, to get rid of unwanted errors.
4. Include libc++ as a required framework to get rid of any C++ file not found related errors.
5. Used Cocoa Pods to compile SwiftyDropbox from GitHub: https://github.com/dropbox/SwiftyDropbox, modify the Podfile in the project folder accordingly. iSee.xcworkspace is the workspace generated. Work with generated .xcworkspace file then, not .xcodeproj file.
6. Install cocoa pods in your Mac. After compiling the sources downloaded from Github using Podfile, the Cocoa Pod will generate Alamofire/SwiftyDropbox etc. frameworks. You should see all the generated frameworks in a folder named “Pods” in your workspace. But only Pods_iSee.framework will be added (automatically I guess?) in Linked Libraries and Frameworks in your app. Anyway, just make sure you are able to import and work with SwiftyDropbox API in your project. 
7. You need to make changes in info.plist in URL types field and LSApplicationQueriesSchemes to make DropBox to work with your Dropbox Developer “appKey” which you initialize in “AppDelegate.swift” file. These instructions are given on GitHub. [Dropbox is integrated with the app for seem-less data collection and upload, (Free) "dropbox-developer account" required.]
8. Include libc++.tbd in linked libraries and frameworks. It is required for some Swix (https://github.com/stsievert/swix) stuff to work. Swix will require opencv2 framework.
