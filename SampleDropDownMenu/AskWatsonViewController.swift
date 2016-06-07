import UIKit

/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
This licensed material is licensed under the Apache 2.0 license. http://www.apache.org/licenses/LICENSE-2.0.
*/

/**
    The following class presents the modal example. Most of the work is actuallvar   done in the DropdownExampleViewController class, so check that out for all
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
import AlchemyLanguageV1
import DialogV1
import CoreData

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
    @IBOutlet weak var clearWatsonTextViewButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewLabel: UILabel!
    @IBOutlet weak var engineeringButton: UIButton!
    
    // MARK: - Constants, Properties
    var isListeningForQuestion = true
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

        prepareDropdownMenuButtonAnimation()
        
        prepareRecordingSession()
        
        prepareLoaderAnimation()
        
        prepareWatsonAnimation()
        
        showWatsonAnimation()
        
        setupWatsonImageViewAsButton()
        
        saveName("Joe Smith")
        
        print(checkCoreDataForUserName())
        
    }
    
    override func viewDidAppear(animated: Bool) {
        watsonTextView.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "toKeywords"){
           
        } else{
            
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
                        //Do something if permission to record is granted
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
    func prepareLoaderAnimation() -> Void {
        loader.animationImages = [UIImage]()
        
        // grabs the animation frames from the bundle
        for index in 0 ..< 60 {
            let frameName = String(format: "\(index)")
            loader.animationImages?.append(UIImage(named:frameName)!)
        }
        for index in 59.stride(to: 0, by: -1){
            let frameName = String(format: "\(index)")
            loader.animationImages?.append(UIImage(named:frameName)!)
        }
        
        loader.animationDuration = 1.5
        loader.stopAnimating()
        loader.hidden = true
    }
    
    func prepareDropdownMenuButtonAnimation() -> Void{
        dropdownButtonImage.animationImages = self.animationImages;
        dropdownButtonImage.animationDuration = Double(self.animationImages.count) / 50.0;
        dropdownButtonImage.animationRepeatCount = 1;
    }
    
    
    func prepareWatsonAnimation()-> Void{
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
    
    func prepareOpenWatson()-> Void{
        watsonImageView.animationImages = [UIImage]()
        
        for i in 34.stride(to: 58, by: 1){
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
    
    func prepareTalkingWatsonOpen() -> Void{
        watsonImageView.animationImages = [UIImage]()
        
        for index in 0 ..< 26{
            let frameName = String(format: "talking_\(index)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
        }
        
        watsonImageView.animationDuration = 0.5
        watsonImageView.stopAnimating()
        watsonImageView.hidden = true
    }
    
    func prepareTalkingWatsonClose() -> Void{
        watsonImageView.animationImages = [UIImage]()
        
        for index in 116 ..< 149{
            let frameName = String(format: "talking_\(index)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
        }
        
        watsonImageView.animationDuration = 0.5
        watsonImageView.stopAnimating()
        watsonImageView.hidden = true
    }

    
    func prepareTalkingWatson() -> Void{
        watsonImageView.animationImages = [UIImage]()
        
        for index in 26 ..< 116{
            let frameName = String(format: "talking_\(index)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
        }
        
        watsonImageView.animationDuration = 2.0
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
            proccessSpeechAndFindKeywords()
        } else {
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
                self.startRecording()
            })
            
            
        } else {
            prepareWatsonAnimation()
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
    
    func showWatsonAnimation()-> Void{
        
        self.watsonImageView.alpha = 1
        self.watsonImageView.animationRepeatCount = 0
        self.watsonImageView.startAnimating()
        self.watsonImageView.hidden = false
        
        //show indeterminate animation
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
        showWatsonAnimation()
    }
    
    func hideWatson() -> Void{
        self.watsonImageView.stopAnimating()
        self.watsonImageView.hidden = true
    }
    
    func processTextAndFindKeywords(){
        
        hideWatson()
        
        hideWatsonTextViewWithAnimation()
    
        showLoaderAndStartAnimation()
        
        disableDropdownMenuFunctionality()
        
        disableClearTextButtonFunctionality()
        
        alchemyLanguage.getRankedKeywords(requestType: .Text, html: nil, url: nil, text: self.watsonTextView.text, completionHandler: { (error, returnValue) in
            // 3. hide loader
            let animationDuration = NSTimeInterval(2.0) * 0.15
            let options = UIViewAnimationOptions.CurveEaseInOut
            
            UIView.animateWithDuration(animationDuration, delay: 1.5,
                options: options, animations: {
                    self.loader.alpha = 0
                }, completion: { finished in
                    
                    let attributedTextViewString = NSMutableAttributedString(string: self.watsonTextView.text)
                    
                    let attributedText = self.findKeywordsAndAddAttribues(returnValue.keywords,
                                                attributedTextViewString: attributedTextViewString, transcription: self.watsonTextView.text)
                    
                    self.addAttributesToWatsonTextView(attributedText)
                    
                    self.showWatsonTextViewWithAnimation()
                    
                    self.enableDropdownMenuFunctionality()
                    
                    self.enableClearTextButtonFunctionality()
            })
        })
    
    }
    
    func proccessSpeechAndFindKeywords() -> Void{
        
        hideWatson()
        
        showLoaderAndStartAnimation()
        
        disableDropdownMenuFunctionality()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        
        let fileURL = paths.stringByAppendingPathComponent("recording.wav")
        
        let data = NSData(contentsOfURL: NSURL(fileURLWithPath: fileURL))
        
        let settings = TranscriptionSettings(contentType: .WAV)
        
        let failure = { (error: NSError) in
            print(error)
            // cleanup loader
            self.loader.stopAnimating()
            self.loader.hidden = true
            
            self.prepareWatsonAnimation()
            self.showWatsonAnimation()
        }

        speechToText.transcribe(data!, settings: settings, failure: failure){
            results in
            if let transcription = results.last?.alternatives.last?.transcript {
                
                print(transcription)
                
                alchemyLanguage.getRankedKeywords(requestType: .Text, html: nil, url: nil, text: transcription, completionHandler: { (error, returnValue) in
                    
                    //After highligting keywords, hide loader
                    let animationDuration = NSTimeInterval(2.0) * 0.15
                    let options = UIViewAnimationOptions.CurveEaseInOut
                    
                    UIView.animateWithDuration(animationDuration, delay: 1.5,
                        options: options, animations: {
                            self.loader.alpha = 0
                        }, completion: { finished in
                            
                            let attributedTextViewString = NSMutableAttributedString(string: transcription)
                            
                            let attributedText = self.findKeywordsAndAddAttribues(returnValue.keywords,
                                attributedTextViewString: attributedTextViewString, transcription: transcription)
                            
                            self.addAttributesToWatsonTextView(attributedText)
                            
                            self.showWatsonTextViewWithAnimation()
                            
                            self.enableDropdownMenuFunctionality()
                            
                    })
                })
            }
        }
    }
    
    func findKeywordsAndAddAttribues(keywords: [AlchemyLanguageV1.Keyword]?, attributedTextViewString: NSMutableAttributedString, transcription: String) -> NSAttributedString{
    
        var colorIndex = 1
        for keyword in keywords!{
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
        
        return attributedTextViewString
    }
    
    func addAttributesToWatsonTextView(text: NSAttributedString) -> Void{
        self.watsonTextView.attributedText = text
        self.watsonTextView.font = UIFont(name: "Lubalin Graph", size: 36)
        self.watsonTextView.textAlignment = .Left
    }
    

    func disableDropdownMenuFunctionality() -> Void{
        self.dropdownButton.enabled = false
    }
    
    func enableDropdownMenuFunctionality() -> Void{
        self.dropdownButton.enabled = true
    }
    
    func disableClearTextButtonFunctionality() -> Void{
        self.clearWatsonTextViewButton.enabled = false
    }
    
    func enableClearTextButtonFunctionality() -> Void{
        self.clearWatsonTextViewButton.enabled = true
    }
    
    
    func hideWatsonTextViewWithAnimation() -> Void{
        UIView.animateWithDuration(4.0, animations: {
            self.watsonTextView.alpha = 0.0
            self.watsonTextView.hidden = true
        })
    }
    
    func hideWatsonTextViewWithAnimationAndPresentHeaderView() -> Void{
        UIView.animateWithDuration(4.0, animations: {
            self.watsonTextView.alpha = 0.0
            self.watsonTextView.hidden = true
            
            self.prepareWatsonAnimation()
            self.showWatsonAnimation()
            
            self.headerView.hidden = false
            self.dropdownButton.hidden = false
            self.dropdownButtonImage.hidden = false
            
            self.headerViewLabel.text = "Ask"
            self.clearWatsonTextViewButton.hidden = true
        })
    }
    
    func showWatsonTextViewWithAnimation() -> Void{
        UIView.animateWithDuration(4.0, animations: {
            self.watsonTextView.alpha = 1.0
            self.watsonTextView.hidden = false
            
            self.dropdownButton.hidden = true
            self.dropdownButtonImage.hidden = true
            
            self.headerViewLabel.text = "Keywords"
            
            self.clearWatsonTextViewButton.hidden = false
        })
    }
    
    func showLoaderAndStartAnimation() -> Void{
        self.loader.startAnimating()

        //show indeterminate loader
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.loader.alpha = 1
            self.loader.hidden = false
        }, completion: nil)
    }
    
    @IBAction func clearWatsonTextViewButtonTapped(sender: AnyObject) {
        hideWatsonTextViewWithAnimationAndPresentHeaderView()
        self.watsonTextView.text = ""
        self.isListeningForQuestion = true
    }
    
    func listenForKeyCommand()-> Void{
        var settings = TranscriptionSettings(contentType: .L16(rate: 44100, channels: 1))
        settings.continuous = true
        settings.interimResults = true
        settings.keywords = ["akshay"]
        settings.keywordsThreshold = 0.75
        
        let failure = { (error: NSError) in print(error) }
        
        let stopStreaming = speechToText.transcribe(settings,
                                                    failure: failure) { results in
                                                        if let transcription = results.last {
                                                            
                                                            let transcriptionText = results.last?.alternatives.last?.transcript
                                                            print(transcriptionText!)
                                                            
                                                            //This will look for the word Watson, while also listeningForQuesiton

                                                            //This is an end of sentence
                                                            if(transcription.keywordResults != nil) && self.isListeningForQuestion == true{
                                                                self.isListeningForQuestion = false
                                                                
                                                            }

                                                        }
        // Streaming will continue until either an end-of-speech event is detected by
        // the Speech to Text service or the `stopStreaming` function is executed.
        }
    }

    @IBAction func engineeringButtonTapped(sender: AnyObject) {
        if self.watsonTextView.text != "" {
        
            self.engineeringButton.enabled = false
            self.watsonTextView.hidden = true

            prepareCloseWatson()
        
            showCloseWatson()
        
            let seconds = watsonCloseDuration
            let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.prepareRecordingWatson()
                self.showWatsonAnimation()
            
                self.watsonSpeak(self.watsonTextView.text)
            })
        }

    }
    
    
    
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        let firstDelay = 0.25 * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let firstDispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(firstDelay))
        
        self.prepareTalkingWatsonClose()
        self.showWatsonAnimation()
        
        dispatch_after(firstDispatchTime, dispatch_get_main_queue(), {
            self.prepareOpenWatson()
            self.showWatsonAnimation()
        })
        
        let delay = 0.75 * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.prepareWatsonAnimation()
            self.showWatsonAnimation()
            self.engineeringButton.enabled = true
            self.watsonTextView.hidden = false
            self.hideWatson()
        })

    }
    
    func watsonSpeak(text: String){
        
        textToSpeech.synthesize(text,
                                audioFormat: AudioFormat.WAV,
                                failure: { error in
                                    print("error was generated \(error)")
                                })
            { data in

                do {
                    
                    self.prepareTalkingWatsonOpen()
                    self.showWatsonAnimation()
                    
                    let secondDelay = 0.2 * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                    let secondDispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(secondDelay))
                    dispatch_after(secondDispatchTime, dispatch_get_main_queue(), {
                        self.prepareTalkingWatson()
                        self.showWatsonAnimation()
                    })
                    
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer!.play()
                    
                    
                } catch {
                    print("Couldn't create player.")
                }
            }
    }
    

}

