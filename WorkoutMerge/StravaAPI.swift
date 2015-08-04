//
//  StravaAPI.swift
//  WorkoutMerge
//
//  Created by Jason Kusnier on 7/28/15.
//  Copyright (c) 2015 Jason Kusnier. All rights reserved.
//

import UIKit
import p2_OAuth2
import HealthKit

class StravaAPI: WorkoutSyncAPI {
    static let sharedInstance = StravaAPI()
    
    let oauth2:OAuth2CodeGrant
    let baseURL = NSURL(string: "https://www.strava.com/api")!
    
    override init() {
        var settings = [
            "authorize_uri": "https://www.strava.com/oauth/authorize",
            "token_uri": "https://www.strava.com/oauth/token",
            "redirect_uris": ["http://www.workoutmerge.com/callback"],
            "secret_in_body": true,
            "verbose": true,
            ] as OAuth2JSON
        
        var myDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("ApiKeys", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            if let strava = dict["strava"] as? NSDictionary {
                settings["client_id"] = strava["client_id"]
                settings["client_secret"] = strava["client_secret"]
                settings["access_token"] = strava["access_token"]
            }
        }
        
        self.oauth2 = OAuth2CodeGrant(settings: settings)
        self.oauth2.viewTitle = "Strava"
        self.oauth2.onAuthorize = { parameters in
            println("Did authorize with parameters: \(parameters)")
        }
        self.oauth2.onFailure = { error in
            if nil != error {
                println("Authorization went wrong: \(error!.localizedDescription)")
            }
        }
        
        super.init(activityTypes: [
            "Ride",
            "Run",
            "Swim",
            "Workout",
            "Hike",
            "Walk"
            ], otherTypes: [String]())
    }
    
    override func authorizeEmbeddedFrom(controller: UIViewController, params: [String : String]?, afterAuthorizeOrFailure: (wasFailure: Bool, error: NSError?) -> Void) {
        let web = self.oauth2.authorizeEmbeddedFrom(controller, params: params)
        
        self.oauth2.afterAuthorizeOrFailure = { wasFailure, error in
            if !wasFailure {
                web.dismissViewControllerAnimated(true, completion: nil)
            }
            afterAuthorizeOrFailure(wasFailure: wasFailure, error: error)
        }
    }
    
    override func disconnect() {
        self.oauth2.forgetTokens()
    }
    
    override class func handleRedirectURL(url: NSURL) {
        sharedInstance.oauth2.handleRedirectURL(url)
    }
    
    override func postActivity(workout: (UUID: NSUUID?, type: String?, startTime: NSDate?, totalDistance: Double?, duration: Double?, averageHeartRate: Int?, totalCalories: Double?, notes: String?, otherType: String?), failure fail : ((NSError?, String) -> ())? = { error in println(error) }, success succeed: ((savedKey: String?) -> ())? = nil) {
        
//        name:	string required
//        type:	string required, case insensitive
//        possible values: ride, run, swim, workout, hike, walk, nordicski, alpineski, backcountryski, iceskate, inlineskate, kitesurf, rollerski, windsurf, workout, snowboard, snowshoe, ebikeride, virtualride
//        start_date_local:	datetime required
//        ISO 8601 formatted date time, see Dates for more information
//        elapsed_time:	integer required
//        seconds
//        description:	string optional
//        distance:	float optional
//        meters
//        private:	integer optional
//        set to 1 to mark the resulting activity as private, ‘view_private’ permissions will be necessary to view the activity
//        trainer:	integer optional
//        set to 1 to mark as a trainer activity
//        commute:	integer optional 
//        set to 1 to mark as commute
    }
    
    override func activityType(t: HKWorkoutActivityType) -> String {
        switch t {
        case .Cycling: return "Ride"
        case .Running: return "Run"
        case .Swimming: return "Swim"
        case .CrossTraining: return "Workout"
        case .Hiking: return "Hike"
        case .Walking: return "Walk"
        default: return "Ride"
        }
        
        // nordicski, alpineski, backcountryski, iceskate, inlineskate, kitesurf, rollerski, windsurf, workout, snowboard, snowshoe, ebikeride, virtualride
    }
    
    override func otherActivityType(t: HKWorkoutActivityType) -> String? {
        switch t {
        default: return nil
        }
    }
}