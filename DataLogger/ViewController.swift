//
//  ViewController.swift
//  DataLogger
//
//  Created by Sashank Vempati on 4/29/21.
// Documentation: https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events
//                https://developer.apple.com/documentation/coremotion/getting_raw_gyroscope_events

import CoreMotion
import UIKit

class ViewController: UIViewController, UIApplicationDelegate {
    
    
    @IBOutlet weak var RecordStatus: UILabel!
    @IBOutlet weak var accelStatus: UILabel!
    
    @IBOutlet weak var gyroStatus: UILabel!
    
    @IBOutlet weak var xAccel: UILabel!
    @IBOutlet weak var yAccel: UILabel!
    @IBOutlet weak var zAccel: UILabel!
    
    @IBOutlet weak var xGyro: UILabel!
    @IBOutlet weak var yGyro: UILabel!
    @IBOutlet weak var zGyro: UILabel!
    
    @IBOutlet weak var timeStamp: UILabel!
    
    var timer : Timer?
    //var timer = Timer()
    var motion = CMMotionManager()
    
    // this 2D list will contain all the IMU data
    var dataCollect = [[Double]]()
    
    // this is updated with the last row value of the 2D array
    var last_index = 0
    
    // checks whether phone is recording when app is running in the background
    var isRecording: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.accelStatus.text = "Loading Accelerometers..."
        self.gyroStatus.text = "Loading Gyroscopes..."
        
        if self.motion.isAccelerometerAvailable {
            // Updates Accelerometer status
            self.accelStatus.text = "Accelerometers Active"
            self.accelStatus.textColor = UIColor.systemGreen

        }
        
        if self.motion.isGyroAvailable {
            // Updates Gyroscope Status
            self.gyroStatus.text = "Gyroscopes Active"
            self.gyroStatus.textColor = UIColor.systemGreen
        }
                
        
    }
    
    @IBAction func onStart(_ sender: Any) {
        // start recording data
        isRecording = true
        startAccelerometers()
        startGyros()
        
    }
    
    @IBAction func onStop(_ sender: Any) {
        isRecording = false
        // Stops collecting accelerometer and gyroscope information
        self.motion.stopAccelerometerUpdates()
        self.motion.stopGyroUpdates()
        
        self.RecordStatus.text = "Record Data"
        self.RecordStatus.textColor = UIColor.systemBlue

    }
    
    @IBAction func onExport(_ sender: Any) {
        self.RecordStatus.text = "Exporting..."
        self.RecordStatus.textColor = UIColor.systemBlue
        
        let sFileName = "IMU.csv"
        
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let documentURL = URL(fileURLWithPath: documentDirectoryPath).appendingPathComponent(sFileName)
        
        let output = OutputStream.toMemory()
        
        let csvwriter = CHCSVWriter(outputStream: output, encoding: String.Encoding.utf8.rawValue, delimiter: ",".utf16.first!)
        
        //HEADER FOR CSV File
        csvwriter?.writeField("Timestamp")
        csvwriter?.writeField("a_x")
        csvwriter?.writeField("a_y")
        csvwriter?.writeField("a_z")
        csvwriter?.writeField("g_x")
        csvwriter?.writeField("g_y")
        csvwriter?.writeField("g_z")
        csvwriter?.finishLine()
        
        //array to add data
        for(elements) in dataCollect.enumerated() {
            csvwriter?.writeField(elements.element[0])  // Timestamp
            csvwriter?.writeField(elements.element[1])  // a_x
            csvwriter?.writeField(elements.element[2])  // a_y
            csvwriter?.writeField(elements.element[3])  // a_z
            csvwriter?.writeField(elements.element[4])  // g_x
            csvwriter?.writeField(elements.element[5])  // g_y
            csvwriter?.writeField(elements.element[6])  // g_z
            
            csvwriter?.finishLine()
        }
        csvwriter?.closeStream()
        
        let buffer = (output.property(forKey: .dataWrittenToMemoryStreamKey) as? Data)!
        
        do {
            try buffer.write(to: documentURL)
        }catch{
            
        }
        
        self.RecordStatus.text = "Exported!"
        self.RecordStatus.textColor = UIColor.systemGreen

        
        print(self.dataCollect)
    }
    
    func startAccelerometers() {
                
        // checks if accelerometer hardware is available
        if self.motion.isAccelerometerAvailable  {
        //if CMSensorRecorder.isAccelerometerRecordingAvailable() {
            self.RecordStatus.text = "Recording..."
            self.RecordStatus.textColor = UIColor.systemRed

            self.motion.accelerometerUpdateInterval = 1.0/500.0  // 60Hz (Sampling rate)
            self.motion.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                //print(data as Any)
                if let trueData = data {
                    self.view.reloadInputViews()
                    var x = trueData.acceleration.x
                    var y = trueData.acceleration.y
                    var z = trueData.acceleration.z
                    var ts = trueData.timestamp
                    
                    x = Double(x).rounded(toPlaces: 4)
                    y = Double(y).rounded(toPlaces: 4)
                    z = Double(z).rounded(toPlaces: 4)
                    ts = Double(ts).rounded(toPlaces: 4)
                    // prints out accelerometer values and timestamp
                    print("Accel:", x, y, z, ts)
                    
                    self.dataCollect.append([ts, x, y, z, 0.0, 0.0, 0.0])
                    self.last_index = self.dataCollect.count - 1 // returns last row of 2D array
                    
                    
                    // updates the accelerometer values on the screen
                    self.xAccel.text = "a_x: \(Double(x).rounded(toPlaces: 3))"
                    self.yAccel.text = "a_y: \(Double(y).rounded(toPlaces: 3))"
                    self.zAccel.text = "a_z: \(Double(z).rounded(toPlaces: 3))"
                    self.timeStamp.text = "\(Double(ts).rounded(toPlaces: 3))"
                    
                    
                }
            }
            
            
        }
    }
    
    func startGyros() {
        if motion.isGyroAvailable {
            self.motion.gyroUpdateInterval = 1.0/500.0  // Sampling rate
            self.motion.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
                if let trueData = data {
                    self.view.reloadInputViews()
                    var x = trueData.rotationRate.x
                    var y = trueData.rotationRate.y
                    var z = trueData.rotationRate.z
                    //var ts = trueData.timestamp
                    
                    x = Double(x).rounded(toPlaces: 4)
                    y = Double(y).rounded(toPlaces: 4)
                    z = Double(z).rounded(toPlaces: 4)
                    
                    
                    // prints out gyroscope values and timestamp
                    //print("Gyro:", x, y, z, ts)
                    print(self.last_index)
                    self.dataCollect[self.last_index][4] = x
                    self.dataCollect[self.last_index][5] = y
                    self.dataCollect[self.last_index][6] = z
                    print(self.dataCollect[self.last_index])
                    
                    // updates the gyroscope values on the screen
                    self.xGyro.text = "g_x: \(Double(x).rounded(toPlaces: 5))"
                    self.yGyro.text = "g_y: \(Double(y).rounded(toPlaces: 5))"
                    self.zGyro.text = "g_z: \(Double(z).rounded(toPlaces: 5))"
                    
                }
            }
            
            
        }
    }
    
    /**
    func startGyros() {
       if motion.isGyroAvailable {
          self.motion.gyroUpdateInterval = 1.0 / 60.0
          self.motion.startGyroUpdates()

          // Configure a timer to fetch the accelerometer data.
          self.timer = Timer(fire: Date(), interval: (1.0/60.0),
                 repeats: true, block: { (timer) in
             // Get the gyro data.
             if let data = self.motion.gyroData {
                let x = data.rotationRate.x
                let y = data.rotationRate.y
                let z = data.rotationRate.z
                let ts = data.timestamp
                
                // Use the gyroscope data in your app.
                print("Gyro:", x, y, z, ts)
                self.xGyro.text = "g_x: \(Double(x).rounded(toPlaces: 3))"
                self.yGyro.text = "g_y: \(Double(y).rounded(toPlaces: 3))"
                self.zGyro.text = "g_z: \(Double(z).rounded(toPlaces: 3))"
                self.timeStamp.text = "\(Double(ts).rounded(toPlaces: 3))"

             }
          })

          // Add the timer to the current run loop.
        RunLoop.current.add(self.timer!, forMode: .default)
       }
    }**/
    
    func stopGyros() {
       if self.timer != nil {
        self.timer?.invalidate()
        self.timer = nil

          self.motion.stopGyroUpdates()
       }
    }
    
    func updateUI() {
        if self.isRecording == true {
            startAccelerometers()
            startGyros()

        } else {
            self.motion.stopAccelerometerUpdates()
            self.motion.stopGyroUpdates()
        }
    }
    
}

extension Double {
    // Rounds decimal to specified number of places
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

