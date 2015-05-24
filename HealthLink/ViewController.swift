//
//  ViewController.swift
//  HealthLink
//
//  Created by Jason Kusnier on 5/23/15.
//  Copyright (c) 2015 Jason Kusnier. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let hkStore = HKHealthStore()
    var workouts = [HKWorkout]()
    
    let refreshControl = UIRefreshControl()
    
    lazy var dateFormatter:NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        formatter.dateStyle = .ShortStyle
        return formatter;
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        let readTypes = Set([
            HKObjectType.workoutType()
        ])
        
        if !HKHealthStore.isHealthDataAvailable() {
            println("HealthKit Not Available")
        } else {
        
            hkStore.requestAuthorizationToShareTypes(nil, readTypes: readTypes, completion: { (success: Bool, err: NSError!) -> () in
                println("okay: \(success) error: \(err)")
                if success {
                    self.readWorkOuts({(results: [AnyObject]!, error: NSError!) -> () in
                        println("Made It \(results.count)")
                        if let workouts = results as? [HKWorkout] {
                            self.workouts = workouts
                            self.tableView.reloadData()
                        }
                    })
                }
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func readWorkOuts(completion: (([AnyObject]!, NSError!) -> Void)!) {

//        let predicate =  HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.)

        let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)

        let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil, limit: 50, sortDescriptors: [sortDescriptor])
            { (sampleQuery, results, error ) -> Void in
                
                if let queryError = error {
                    println( "There was an error while reading the samples: \(queryError.localizedDescription)")
                }
                completion(results, error)
        }

        hkStore.executeQuery(sampleQuery)
    }
    
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return workouts.count
    }
    
    func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        let workout  = self.workouts[indexPath.row]
        let startDate = dateFormatter.stringFromDate(workout.startDate)
        
        cell.textLabel!.text = startDate
        cell.detailTextLabel!.text = stringFromTimeInterval(workout.duration)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {}
    
    func stringFromTimeInterval(interval:NSTimeInterval) -> String {
        
        var ti = NSInteger(interval)
        
        var seconds = ti % 60
        var minutes = (ti / 60) % 60
        var hours = (ti / 3600)
        
        return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        self.readWorkOuts({(results: [AnyObject]!, error: NSError!) -> () in
            println("Made It \(results.count)")
            if let workouts = results as? [HKWorkout] {
                self.workouts = workouts
                self.tableView.reloadData()
            }
            
            self.refreshControl.endRefreshing()
        })
    }
}

