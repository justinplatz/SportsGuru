import UIKit
import AVFoundation
import SpeechToTextV1

class DropdownExampleViewController2: ExampleNobelViewController, DropDownViewControllerDelegate, NSURLSessionDelegate, AVAudioRecorderDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var dropdownButtonImage: UIImageView!
    @IBOutlet weak var dropdownButton: UIButton!
    @IBOutlet weak var dropdownView: UIView!
    
    @IBOutlet weak var recordingButton: UIButton!
    
    // MARK: - Constants, Properties
    
    var isOpen = false
    var dropdownVC: DropdownViewController!
    let animationMultiplier : CGFloat = 1;
    let animationImages: [UIImage] = [
        UIImage(named: "circle_x_00")!,
        UIImage(named: "circle_x_01")!,
        UIImage(named: "circle_x_02")!,
        UIImage(named: "circle_x_03")!,
        UIImage(named: "circle_x_04")!,
        UIImage(named: "circle_x_05")!,
        UIImage(named: "circle_x_06")!,
        UIImage(named: "circle_x_07")!
    ];
    var reversedAnimationImages: [UIImage] { get { return animationImages.reverse() } }
    
    var hiddenStatusBar:Bool = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    let dropdownTransitioningDelegate = DropdownTransitioningDelegate()
    
    var player: AVAudioPlayer? = nil
    var recorder: AVAudioRecorder!
    var isStreamingDefault = false
    var stopStreamingDefault: (Void -> Void)? = nil

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.alpha = 0
        
        dropdownButtonImage.animationImages = self.animationImages;
        dropdownButtonImage.animationDuration = Double(self.animationImages.count) / 50.0;
        dropdownButtonImage.animationRepeatCount = 1;
        
    }
    
    func failure(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        dropdownVC = segue.destinationViewController as! DropdownViewController
        
        dropdownVC.modalPresentationStyle = .Custom
        dropdownVC.transitioningDelegate = dropdownTransitioningDelegate
        
        dropdownVC.dropdownPressed = {(index: Int) -> Void in
            self.hiddenStatusBar = false
        }
        
        hiddenStatusBar = false
        
        if segue.identifier == "embedSegue" {
            let childViewController = segue.destinationViewController as! DropdownViewController
            childViewController.delegate = self
        }
    }
    
    // MARK: - Transition Animations
    
    func show(completion: () -> Void) {
        dropdownButtonImage.animationImages = self.animationImages;
        dropdownButtonImage.image = (dropdownButtonImage.animationImages?.last)! as UIImage
        dropdownButtonImage.startAnimating()
        
        let delay = dropdownButtonImage.animationDuration * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), { () -> Void in
            self.dropdownButtonImage.stopAnimating()
        })
        
        let animationDuration = Double(self.animationMultiplier) * 1 / 2.5;
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.backgroundView.alpha = 1
        })
        
    }
    
    func hide(completion: () -> Void ) {
        dropdownButtonImage.animationImages = self.reversedAnimationImages
        dropdownButtonImage.image = (dropdownButtonImage.animationImages?.last)! as UIImage
        dropdownButtonImage.startAnimating()
        
        let delay = dropdownButtonImage.animationDuration * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), { () -> Void in
            self.dropdownButtonImage.stopAnimating()
        })
        
        let animationDuration = Double(self.animationMultiplier) * 1 / 2.5;
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            self.backgroundView.alpha = 0
        })
        
    }
    
    // MARK: - Actions
    
    @IBAction func buttonAction(sender: AnyObject) {
        dropdownVC.toggle()
        self.toggle()
    }
    
    func toggle() {
        if (isOpen) {
            hide { () -> () in
                false
            }
            isOpen = false
        } else {
            show { () -> () in
                false
            }
            isOpen = true
        }
    }
    
    // MARK: - DropDownViewControllerDelegate
    
    func dropDownViewControllerDidPressButton(viewController: DropdownViewController) {
        toggle()
    }
    
    // MARK: - Appearance
    
    override func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Fade
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return hiddenStatusBar
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
//    @IBAction func sendButtonTapped(sender: AnyObject) {
//        //Use image name from bundle to create NSData
//        let image : UIImage = UIImage(named: "curcur.jpg")!
//        
//        //Now use image to create into NSData format
//        let imageData:NSData = UIImagePNGRepresentation(image)!
//        
//        let strBase64:String = imageData.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
//        
//        //print(strBase64)
//        print("Request Sent ...")
//        sendHTTPPostImage(strBase64)
//        
//    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
    }
    
    func sendHTTPPostImage(image: String) -> Void{
        let request = NSMutableURLRequest(URL: NSURL(string: faceRecognitionEndpoint)!)
        request.HTTPMethod = "POST"
        
        let dict = ["image": image]
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(dict as NSDictionary, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
       
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
            guard error == nil && data != nil else{                                                          // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                print("\r\nERROR: statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
            }
                
            else if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding){
                print("responseString = \(responseString)")
                
                let jsonDict = self.convertStringToDictionary(responseString as String)
                let player_name = jsonDict!["response"]?["player_name"]
                let player_summary = jsonDict!["response"]?["player_summary"]
                let match_confidence = jsonDict!["response"]?["match_confidence"]
                
                print(player_name as! String)
                print(player_summary as! String)
                print(match_confidence as! Double)
                
            }
        })
        task.resume()
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }

    @IBAction func recordingButtonTapped(sender: AnyObject) {
        // stop if already streaming
        if (isStreamingDefault) {
            stopStreamingDefault?()
            recordingButton.setImage(UIImage(named: "recording.png"), forState: UIControlState.Normal)
            isStreamingDefault = false
            return
        }
        
        // set streaming
        isStreamingDefault = true
        
        // change button title
        recordingButton.setImage(UIImage(named: "stop.png"), forState: UIControlState.Normal)


        
        // configure settings for streaming
        var settings = TranscriptionSettings(contentType: .L16(rate: 44100, channels: 1))
        settings.continuous = false
        settings.interimResults = true
        
        // start streaming from microphone
        stopStreamingDefault = speechToText.transcribe(settings, failure: failureDefault) { results in
            self.showResults(results)
        }
    }
    
    func failureDefault(error: NSError) {
        let title = "Speech to Text Error:\nStreaming (Default)"
        let message = error.localizedDescription
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in
            self.stopStreamingDefault?()
            self.recordingButton.enabled = true
            self.recordingButton.setImage(UIImage(named: "recording.png"), forState: UIControlState.Normal)
            self.isStreamingDefault = false
        }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
        
        stopStreamingDefault?()
        recordingButton.setImage(UIImage(named: "recording.png"), forState: UIControlState.Normal)
        isStreamingDefault = false
    }
    
    func showResults(results: [TranscriptionResult]) {
        var text = ""
        
        for result in results {
            if let transcript = result.alternatives.last?.transcript where result.final == true {
                let title = titleCase(transcript)
                text += String(title.characters.dropLast()) + "." + " "
                recordingButton.setImage(UIImage(named: "recording.png"), forState: UIControlState.Normal)
            }
        }
        
        if results.last?.final == false {
            if let transcript = results.last?.alternatives.last?.transcript {
                text += titleCase(transcript)
            }
        }
        
        //self.transcriptionField.text = text
        print(text)
    }
    
    func titleCase(s: String) -> String {
        let first = String(s.characters.prefix(1)).uppercaseString
        return first + String(s.characters.dropFirst())
    }
}
