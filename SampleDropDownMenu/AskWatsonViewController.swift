import UIKit

/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
This licensed material is licensed under the Apache 2.0 license. http://www.apache.org/licenses/LICENSE-2.0.
*/

/**
    The following class presents the modal example. Most of the work is actually
    done in the DropdownExampleViewController class, so check that out for all
    of the animation implementation.

    This class just hands off some dependencies to the
    DropdownExampleViewController once the button is clicked. See the
    prepareForSegue:sender: method to see what is being handed off.

    This class subclasses ExampleNobelViewController in order to get a dummy
    set of data to display in a UITableView. It is not necessary to understand
    how that class functions in order to follow the animation example code.
*/


import AVFoundation
import TextToSpeechV1
import SpeechToTextV1

func getDocumentsDirectory() -> String {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

class AskWatsonViewController: ExampleNobelViewController, DropDownViewControllerDelegate, UITextViewDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    // MARK: - Outlets

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var dropdownButtonImage: UIImageView!
    @IBOutlet weak var dropdownButton: UIButton!
    @IBOutlet weak var dropdownView: UIView!
    @IBOutlet weak var watsonTextView: UITextView!
    @IBOutlet weak var loader: UIImageView!
    @IBOutlet weak var watsonImageView: UIImageView!
    
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
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.alpha = 0
        
        dropdownButtonImage.animationImages = self.animationImages;
        dropdownButtonImage.animationDuration = Double(self.animationImages.count) / 50.0;
        dropdownButtonImage.animationRepeatCount = 1;
        
        prepareRecordingSession()
        
        prepareLoader()
        
        prepareWatson()
        showWatson()
        setupWatsonImageViewAsButton()

    }
    
    override func viewDidAppear(animated: Bool) {
        watsonTextView.delegate = self
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
    
    /*
     This function will be called in the viewDidLoad in order to add all style,
     colors, ... etc to any UI elements
     */
    func setUpViewUI() -> Void{
        self.view.backgroundColor = UIColor.lightGrayBackground()
        
        //self.navigationBar.barTintColor = UIColor.darkGrayBackground()
    }
    
    /*
     This function tells UITextView to end editing if the return key is pressed.
     */
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            processTextAndFindKeywords()
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    
    /*
     This function will be called in the viewDidLoad
     This function looks for permission to use the microphone
     If permission is granted, it calls loadRecordingUI(),
     else, it does nothing.
     */
    func prepareRecordingSession() -> Void{
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                dispatch_async(dispatch_get_main_queue()) {
                    if allowed {
                        //self.loadRecordingUI()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    /*
     This function simply adds all the animation images to the loader,
     and prepares it to be used later
     */
    func prepareLoader() -> Void {
        loader.animationImages = [UIImage]()
        
        // grabs the animation frames from the bundle
        for index in 100 ..< 147 {
            let frameName = String(format: "Loader_00%03d", index)
            loader.animationImages?.append(UIImage(named:frameName)!)
        }
        
        loader.animationDuration = 1.5
        loader.stopAnimating()
        loader.hidden = true
    }
    
    
    func prepareWatson()-> Void{
        watsonImageView.animationImages = [UIImage]()
        for i in 0 ..< 11{
            let frameName = String(format: "frame_\(i)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)

        }
        
        for i in 10.stride(to: 0, by: -1){
            let frameName = String(format: "frame_\(i)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)

        }
        
        watsonImageView.animationDuration = 1.25
        watsonImageView.stopAnimating()
        watsonImageView.hidden = true
    }
    
    func prepareCloseWatson()-> Void{
        watsonImageView.animationImages = [UIImage]()
        
        for i in 58.stride(to: 34, by: -1){
            let frameName = String(format: "tmp-\(i)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
        }
        watsonImageView.animationDuration = watsonCloseDuration
        watsonImageView.animationRepeatCount = 1
        watsonImageView.stopAnimating()
        watsonImageView.hidden = true
    }
    
    func prepareRecordingWatson()-> Void{
        watsonImageView.animationImages = [UIImage]()
        
        for i in 33.stride(to: 0, by: -1){
            let frameName = String(format: "tmp-\(i)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
        }
        
        for i in 0.stride(to: 33, by: 1){
            let frameName = String(format: "tmp-\(i)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
        }

        
        watsonImageView.animationDuration = 3.0
        watsonImageView.stopAnimating()
        watsonImageView.hidden = true
    }

    
    
    func setupWatsonImageViewAsButton() -> Void{
        watsonImageView.userInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AskWatsonViewController.watsonImageTapped(_:)))
        watsonImageView.addGestureRecognizer(tapRecognizer)
    }
    
    func watsonImageTapped(gestureRecognizer: UITapGestureRecognizer) {
        recordTapped()
    }
    
    
//    /*
//     This function changes the UI of the record Button on viewDidLoad
//     */
//    func loadRecordingUI() {
//        self.recordButton.setTitle("Tap to Record", forState: .Normal)
//        self.recordButton.titleLabel?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
//        self.recordButton.addTarget(self, action: #selector(recordTapped), forControlEvents: .TouchUpInside)
//    }
    
    /*
     This function is called each time the record button is pressed while not recording.
     If recording and record button is pressed, finishRecording() is called
     */
    func startRecording() {
        let audioFilename = getDocumentsDirectory().stringByAppendingPathComponent("recording.wav")
        let audioURL = NSURL(fileURLWithPath: audioFilename)
        
        
        
        let settings:[String:AnyObject] = [ AVFormatIDKey:Int(kAudioFormatLinearPCM), AVLinearPCMIsFloatKey:false, AVLinearPCMIsBigEndianKey:0, AVLinearPCMIsNonInterleaved:false, AVSampleRateKey:44100.0, AVNumberOfChannelsKey:2, AVEncoderBitRateKey:12800, AVLinearPCMBitDepthKey:16, AVEncoderAudioQualityKey:AVAudioQuality.Max.rawValue]
        
        do {
            audioRecorder = try AVAudioRecorder(URL: audioURL, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            //recordButton.setTitle("Tap to Stop", forState: .Normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    /*
     This function is called each time the record button is pressed while  recording.
     If not recording and record button is pressed, startRecording() is called
     After a successful recording, proccessSpeechAndFindKeywords() is called
     */
    func finishRecording(success success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            //recordButton.setTitle("Tap to Re-record", forState: .Normal)
            proccessSpeechAndFindKeywords()
        } else {
            //recordButton.setTitle("Tap to Record", forState: .Normal)
            // recording failed :(
        }
    }
    
    /*
     This function is called as a result of tapping the record button.
     It determines whether to call the start or finish recording functions
     */
    func recordTapped() {
        if audioRecorder == nil {
            
            prepareCloseWatson()
            
            showCloseWatson()
            
            let seconds = watsonCloseDuration
            let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                
                self.prepareAndShowRecordingWatson()
                
            })
            
            startRecording()
        } else {
            prepareWatson()
            finishRecording(success: true)
        }
    }
    
    /*
     While editing UITextField, if a single tap is recognized this function tells the view to end editing
     */
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func showWatson()-> Void{
        self.watsonImageView.alpha = 1
        self.watsonImageView.animationRepeatCount = 0
        self.watsonImageView.startAnimating()
        self.watsonImageView.hidden = false
        
        // 2. show indeterminate loader
        UIView.animateWithDuration(4.0, delay:0.0, options: [.Repeat, .Autoreverse], animations: { () -> Void in
        }, completion: nil)

    }
    
    func showCloseWatson()-> Void{
        self.watsonImageView.alpha = 1
        self.watsonImageView.startAnimating()
        self.watsonImageView.hidden = false
    }
    
    func prepareAndShowRecordingWatson() -> Void{
        prepareRecordingWatson()
        showWatson()
    }
    
    func hideWatson() -> Void{
        // 4a. cleanup loader
        self.watsonImageView.stopAnimating()
        self.watsonImageView.hidden = true
    }
    
    func processTextAndFindKeywords(){
        hideWatson()
        self.loader.alpha = 0
        self.loader.startAnimating()
        self.loader.hidden = false
        
        // 2. show indeterminate loader
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.loader.alpha = 1
            }, completion: nil)
        
        alchemyLanguage.getRankedKeywords(requestType: .Text, html: nil, url: nil, text: self.watsonTextView.text, completionHandler: { (error, returnValue) in
            // 3. hide loader
            let animationDuration = NSTimeInterval(2.0) * 0.15
            let options = UIViewAnimationOptions.CurveEaseInOut
            UIView.animateWithDuration(animationDuration, delay: 1.5,
                options: options, animations: {
                    self.loader.alpha = 0
                }, completion: { finished in
                    
                    // 4a. cleanup loader
                    self.loader.stopAnimating()
                    self.loader.hidden = true
                    
                    // This will give me an attributedString with the base text-style
                    let attributedTextViewString = NSMutableAttributedString(string: self.watsonTextView.text)
                    
                    var colorIndex = 1
                    for keyword in returnValue.keywords!{
                        let regex = try? NSRegularExpression(pattern: keyword.text!, options: [])
                        let matches = regex!.matchesInString(self.watsonTextView.text, options: [], range: NSMakeRange(0, self.watsonTextView.text.characters.count))
                        
                        for match in matches {
                            let matchRange = match.rangeAtIndex(0)
                            attributedTextViewString.addAttribute(NSForegroundColorAttributeName, value: assignColor(colorIndex), range: matchRange)
                        }
                        
                        print(keyword.text)
                        colorIndex += 1
                    }
                    self.watsonTextView.attributedText = attributedTextViewString
                    self.watsonTextView.font = UIFont(name: "Lubalin Graph", size: 24)
                    self.watsonTextView.textAlignment = .Center
                    self.showWatson()
                    
            })
        })
    
    }
    
    func proccessSpeechAndFindKeywords() -> Void{
        hideWatson()
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        let fileURL = paths.stringByAppendingPathComponent("recording.wav")
        
        let settings = TranscriptionSettings(contentType: .WAV)
        
        let failure = { (error: NSError) in print(error) }
        
        
        let data = NSData(contentsOfURL: NSURL(fileURLWithPath: fileURL))
        self.loader.alpha = 0
        self.loader.startAnimating()
        self.loader.hidden = false
        
        // 2. show indeterminate loader
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.loader.alpha = 1
            }, completion: nil)
        
        speechToText.transcribe(data!, settings: settings, failure: failure){
            results in
            if let transcription = results.last?.alternatives.last?.transcript {
                print(transcription)
                alchemyLanguage.getRankedKeywords(requestType: .Text, html: nil, url: nil, text: transcription, completionHandler: { (error, returnValue) in
                    // 3. hide loader
                    let animationDuration = NSTimeInterval(2.0) * 0.15
                    let options = UIViewAnimationOptions.CurveEaseInOut
                    UIView.animateWithDuration(animationDuration, delay: 1.5,
                        options: options, animations: {
                            self.loader.alpha = 0
                        }, completion: { finished in
                            
                            // 4a. cleanup loader
                            self.loader.stopAnimating()
                            self.loader.hidden = true
                            
                            // This will give me an attributedString with the base text-style
                            let attributedTextViewString = NSMutableAttributedString(string: transcription)
                            
                            var colorIndex = 1
                            for keyword in returnValue.keywords!{
                                let regex = try? NSRegularExpression(pattern: keyword.text!, options: [])
                                let matches = regex!.matchesInString(transcription, options: [], range: NSMakeRange(0, transcription.characters.count))
                                
                                for match in matches {
                                    let matchRange = match.rangeAtIndex(0)
                                    attributedTextViewString.addAttribute(NSForegroundColorAttributeName, value: assignColor(colorIndex), range: matchRange)
                                }
                                
                                print(keyword.text)
                                colorIndex += 1
                            }
                            self.watsonTextView.attributedText = attributedTextViewString
                            self.watsonTextView.font = UIFont(name: "Lubalin Graph", size: 24)
                            self.watsonTextView.textAlignment = .Center
                            self.showWatson()
                    })
                })
            }
        }
    }
    
    
}
