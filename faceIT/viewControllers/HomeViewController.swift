//
//  HomeViewController.swift
//  faceIT
//  Updated by George Yao
//  Last update: December 6th, 2018

import UIKit
import SceneKit
import ARKit
import Vision
import ObjectiveC
import RxSwift
import RxCocoa
import Async
import PKHUD
import Toast_Swift

var courseId = 1
var course = Course.init(courseId: courseId)
var todayAttendance: [Student] = course.getStudents().sorted(by: { $0.name > $1.name })
var weekOfAttendance: [String : [Student]] = course.getWeekAttendances() // KEY
var weekOfData : [String : Int] = [:] // course.getWeeklyPresentCount(weekData: weekOfAttendance)
var weekDataAvg : String = ""
var weekDataToday  : String = ""
var weekDataMax : (String, String) = ("","")
var weekDataMin : (String, String) = ("","")

class HomeViewController: UIViewController, ARSCNViewDelegate {
    var courseIndex = 0

    @IBOutlet var startAttendanceButton: UIButton!
    @IBOutlet var statsButton: UIButton!
    @IBOutlet var courseButton: UIButton!
    @IBOutlet var manualAddButton: UIButton!
    @IBOutlet var downloadStatus: UILabel!
    @IBOutlet var activityView: UIActivityIndicatorView!
    @IBOutlet var sceneView: ARSCNView!
    override func viewDidLoad() {
        super.viewDidLoad()
        activityView.startAnimating()
        
        //rounded corners
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        self.sceneView.layer.cornerRadius = 10
        self.sceneView.layer.masksToBounds = true
        self.downloadStatus.text = modelStatus
        self.startAttendanceButton.layer.cornerRadius = 10
        self.startAttendanceButton.layer.masksToBounds = true
        self.statsButton.layer.cornerRadius = 10
        self.statsButton.layer.masksToBounds = true
        self.courseButton.layer.cornerRadius = 10
        self.courseButton.layer.masksToBounds = true
        self.manualAddButton.layer.cornerRadius = 10
        self.manualAddButton.layer.masksToBounds = true
      
        // Do any additional setup after loading the view.
        weekOfData = course.getWeeklyPresentCount(weekData: weekOfAttendance)
        weekDataAvg = course.calcWeekAverage(weeklyPresentCount: weekOfData)
        weekDataToday = course.calcToday(weeklyPresentCount: weekOfData)
        weekDataMax = course.calcWeekMax(weeklyPresentCount: weekOfData)
        weekDataMin = course.calcWeekMin(weeklyPresentCount: weekOfData)
  }
    
    func download(destinationFileUrl: URL, completionBlock: @escaping (String) -> Void) {
        //Create URL to the source file you want to download
        DispatchQueue.main.async{
            let fileURL = URL(string: "http://attendify.us-east-1.elasticbeanstalk.com/models/download")
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig)
            let request = URLRequest(url:fileURL!)
            let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    // Success
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        completionBlock("done")
                        print("Successfully downloaded. Status code: \(statusCode)")
                    }
                    do {
                        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                    } catch (let writeError) {
                        print("Error creating a file \(destinationFileUrl) : \(writeError)")
                    }
                } else {
                    print("Error took place while downloading a file. Error description: %@", error?.localizedDescription ?? "nil");
                }
            }
            
            task.resume()
        }
    }
  
  @IBAction func changeCourse(_ sender: AnyObject) {
    print("Button tap leads to function call")
    let allCourses = course.getCourses()
    if allCourses.count <= 1 {
      self.view.makeToast("Only one course available", duration: 1.0, position: .center)
    }
    courseIndex += 1
    if (courseIndex > allCourses.count - 1) {
      courseIndex = 0
    }
    courseId = allCourses[courseIndex].1
    course = Course.init(courseId: courseId)
    sender.setTitle(allCourses[courseIndex].0, for: .normal)
    if allCourses.count > 1 {
        self.view.makeToast("Course is set to \(allCourses[courseIndex].0)", duration: 1.0, position: .center)
    }
  }
}
