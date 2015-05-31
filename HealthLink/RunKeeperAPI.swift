//
//  RunKeeperAPI.swift
//  HealthLink
//
//  Created by Jason Kusnier on 5/27/15.
//  Copyright (c) 2015 Jason Kusnier. All rights reserved.
//

import Foundation
import p2_OAuth2

class RunKeeperAPI {
    static let sharedInstance = RunKeeperAPI()
    
    let oauth2:OAuth2CodeGrant
    let baseURL = NSURL(string: "https://api.runkeeper.com")!
    
    init() {
        var settings = [
            "authorize_uri": "https://runkeeper.com/apps/authorize",
            "token_uri": "https://runkeeper.com/apps/token",
            "redirect_uris": ["healthlink://oauth.runkeeper/callback"],
            "secret_in_body": true,
            "verbose": true,
        ] as OAuth2JSON
        
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("ApiKeys", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            if let runKeeper = dict["runKeeper"] as? NSDictionary {
                settings["client_id"] = runKeeper["client_id"]
                settings["client_secret"] = runKeeper["client_secret"]
            }
        }
                
        self.oauth2 = OAuth2CodeGrant(settings: settings)
        self.oauth2.viewTitle = "RunKeeper"
        self.oauth2.onAuthorize = { parameters in
            println("Did authorize with parameters: \(parameters)")
        }
        self.oauth2.onFailure = { error in
            if nil != error {
                println("Authorization went wrong: \(error!.localizedDescription)")
            }
        }
    }
    
    func authorize() {
        self.oauth2.authorize()
    }
    
    class func handleRedirectURL(url: NSURL) {
        sharedInstance.oauth2.handleRedirectURL(url)
    }
    
    func postActivity(workout: (type: String?, startTime: NSDate?, totalDistance: Double?, duration: Double?, averageHeartRate: Int?, totalCalories: Double?, notes: String?), failure fail : (NSError? -> ())? = { error in println(error) }, success succeed: (() -> ())? = nil) {
        let path = "/fitnessActivities"
        let url = baseURL.URLByAppendingPathComponent(path)
        let req = oauth2.request(forURL: url)
        
        var jsonData = [String]()
        if let type = workout.type {
            jsonData.append("\"type\":\"\(type)\"")
        }
        if let startTime = workout.startTime {
            let dateFormatter = NSDateFormatter()
            // Sat, 1 Jan 2011 00:00:00
            dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss"
            let startTimeString = dateFormatter.stringFromDate(startTime)
            
            jsonData.append("\"start_time\":\"\(startTimeString)\"")
        }
        if let totalDistance = workout.totalDistance {
            jsonData.append("\"total_distance\":\(totalDistance)")
        }
        if let duration = workout.duration {
            jsonData.append("\"duration\":\(duration)")
        }
        if let averageHeartRate = workout.averageHeartRate {
            jsonData.append("\"average_heart_rate\":\(averageHeartRate)")
        }
        if let totalCalories = workout.totalCalories {
            jsonData.append("\"total_calories\":\(totalCalories)")
        }
        if let notes = workout.notes {
            jsonData.append("\"notes\":\"\(notes)\"")
        }
        
        var joiner = ","
        var jsonString = "{" + joiner.join(jsonData) + "}"
        
        req.HTTPBody = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        req.HTTPMethod = "POST"
        req.setValue("application/vnd.com.runkeeper.NewFitnessActivity+json", forHTTPHeaderField: "Content-Type")
        
        let queue = NSOperationQueue()
        NSURLConnection.sendAsynchronousRequest(req, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                        println("success")
                        succeed!()
                    } else {
                        println("failure")
                    }
                } else {
                    println("fail")
                }
            })
        })
    }
}