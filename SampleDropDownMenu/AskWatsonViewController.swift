import UIKit

/*
Licensed Materials - Property of IBM
© Copyright IBM Corporation 2015. All Rights Reserved.
This licensed material is licensed under the Apache 2.0 license. http://www.apache.org/licenses/LICENSE-2.0.
*/
//https://sports-sms-test.mybluemix.net/rest/queryagents?test=true&text=
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
import CoreData
import AudioToolbox

func getDocumentsDirectory() -> String {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

class AskWatsonViewController: ExampleNobelViewController, DropDownViewControllerDelegate, UITextViewDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSURLSessionDelegate {

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
    @IBOutlet weak var recordingButton: UIButton!
    
    @IBOutlet weak var tapToContinueView: UIView!
    @IBOutlet weak var tapToContinueLabel: UILabel!
    @IBOutlet weak var tapToContinueImage: UIImageView!
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var imagePicked: UIImageView!
    
    @IBOutlet weak var playerCardView: UIView!
    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var playerPosistionLabel: UILabel!
    @IBOutlet weak var playerBirthdayLabel: UILabel!
    @IBOutlet weak var playerBirthplaceLabel: UILabel!
    @IBOutlet weak var playerHeightWeightLabel: UILabel!
    @IBOutlet weak var playerCurrentTeamLabel: UILabel!
    @IBOutlet weak var playerHeadshotImageView: UIImageView!
    @IBOutlet weak var playerSummaryTextView: UITextView!
    @IBOutlet weak var playerCurrentTeamLogo: UIImageView!
    
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
    
    var player: AVAudioPlayer? = nil
    var recorder: AVAudioRecorder!
    var isStreamingDefault = false
    var stopStreamingDefault: (Void -> Void)? = nil
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        prepareDropdownMenuButtonAnimation()
        
        prepareLoaderAnimation()
        
        prepareWatsonAnimation()
        
        showWatsonAnimation()
        
        setupTapToContinueViewAsButton()
        
        addEffectToButton()
        
        watsonTextView.text = "\"Ask me anything\""
        
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
        toggle()
        watsonTextView.text = ""
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
            //processTextAndFindKeywords()
            textView.resignFirstResponder()
            return false
        }
        return true
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
        watsonImageView.image = nil
        watsonImageView.animationImages = [UIImage]()
        
        for i in 44.stride(to: 34, by: -1){
            let frameName = String(format: "tmp-\(i)")
            watsonImageView.animationImages?.append(UIImage(named:frameName)!)
        }
        watsonImageView.animationDuration = 0.5
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

    func setupTapToContinueViewAsButton() -> Void{
        tapToContinueView.userInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(AskWatsonViewController.tapToContinueTapped(_:)))
        tapToContinueView.addGestureRecognizer(tapRecognizer)
    }
    
    func tapToContinueTapped(gestureRecognizer: UITapGestureRecognizer? = nil) {
        if watsonTextView.text != "" {
        
            recordingButton.hidden = true
            clearWatsonTextViewButton.hidden = true
            clearWatsonTextViewButton.enabled = false
            
            prepareRecordingWatson()

            let seconds = watsonCloseDuration
            let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.showWatsonAnimation()
                //self.AskQuestionAndReturnAnswerAsString(self.watsonTextView.text)
                self.AskDialogAndReturnAnswerAsString(self.watsonTextView.text)
            })
        }
    }
    
    func addEffectToButton() -> Void{
        let pulse1 = CASpringAnimation(keyPath: "transform.scale")
        pulse1.duration = 0.6
        pulse1.fromValue = 1.0
        pulse1.toValue = 1.18
        pulse1.autoreverses = true
        pulse1.repeatCount = 1
        pulse1.initialVelocity = 0.5
        pulse1.damping = 0.8
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 10.0
        animationGroup.repeatCount = 1000
        animationGroup.animations = [pulse1]
        
        recordingButton.layer.addAnimation(animationGroup, forKey: "pulse")
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
    
    func openCamera(){
        self.watsonSpeakNoAnimation("Let me see!")

        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openPhotoLibrary(){
        self.watsonSpeakNoAnimation("Let me see!")

        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
            imagePicker.allowsEditing = true
            imagePicker.showsCameraControls = true
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    class func imageWithImage(image: UIImage, scaledToSize newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(newSize)
        image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        self.recordingButton.hidden = true
        
        self.hideWatson()
        self.loader.alpha = 1
        
        self.dismissViewControllerAnimated(true, completion: nil);
        
        //Now use image to create into NSData format
        let dataForJPEGFile: NSData = UIImageJPEGRepresentation(image, 0.5)!
        
        let strBase64:String = dataForJPEGFile.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
        
        print("Done Encoding ...")
        
        sendHTTPPostImage(strBase64)
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
        recordingButton.hidden = false
        dropdownButton.hidden = false
        watsonTextView.text = ""
    }
    
    
    func checkForOpenCamera(text: String) -> Bool{
        if text.containsString("who is this player") ||
            text.containsString("take a picture") ||
            text.containsString("take a photo") ||
            text.containsString("who is this guy") ||
            text.containsString("see") ||
            text.containsString("look") ||
            text.containsString("check out")
        {
            return true
        }
        return false
    }
    
    
    func proccessSpeechAndFindKeywords() -> Void{
        
        recordingButton.hidden = true
        dropdownButton.hidden = true
        
        showLoaderAndStartAnimation()
        
        if watsonTextView.text == "" {
            loader.alpha = 0
            
            recordingButton.hidden = false
            recordingButton.enabled = true
            dropdownButton.enabled = true
            dropdownButton.hidden = false

            stopAndResetAudioPlayer()
            
            prepareOpenWatson()
            showWatsonAnimation()
            
            let delay = 0.5 * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.prepareWatsonAnimation()
                self.showWatsonAnimation()
            })

            return
        }
        
        //If the command is to take a picture
        if(checkForOpenCamera(watsonTextView.text.lowercaseString)){
            self.openCamera()
        }
        //else if(watsonTextView.text.containsString("player in this photo")){
        //    self.openPhotoLibrary()
        //}
        else{
            tapToContinueTapped()
        }

    }
    

    func disableDropdownMenuFunctionality() -> Void{
        self.dropdownButton.enabled = false
    }
    
    func enableDropdownMenuFunctionality() -> Void{
        dropdownButton.enabled = true
    }
    
    func disableClearTextButtonFunctionality() -> Void{
        self.clearWatsonTextViewButton.enabled = false
    }
    
    func enableClearTextButtonFunctionality() -> Void{
        self.clearWatsonTextViewButton.enabled = true
    }

    func hideWatsonTextViewWithAnimationAndPresentHeaderView() -> Void{
        UIView.animateWithDuration(4.0, animations: {

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

            self.dropdownButton.hidden = true
            self.dropdownButtonImage.hidden = true
            
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
        watsonTextView.text = ""
        
        recordingButton.hidden = false
        recordingButton.enabled = true
        
        tapToContinueView.hidden = true
        stopAndResetAudioPlayer()
    }
    
    func playStartRecordingBeep() -> Void{
        let badumSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("blip1", ofType: "wav")!)
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOfURL: badumSound)
        } catch {
            print("No sound found by URL:\(badumSound)")
        }
        
        dispatch_after(0, dispatch_get_main_queue(), {
            self.audioPlayer!.prepareToPlay()
            self.audioPlayer!.play()
        })
    }
    
    func playEndRecordingBeep() -> Void{
        let badumSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("blip2", ofType: "wav")!)
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOfURL: badumSound)
        } catch {
            print("No sound found by URL:\(badumSound)")
        }
        
        dispatch_after(0, dispatch_get_main_queue(), {
            self.audioPlayer!.prepareToPlay()
            self.audioPlayer!.play()
        })
       
    }
    
    func stopAndResetAudioPlayer(){
        audioPlayer?.pause()
        audioPlayer?.currentTime = 0
    }
    
    func watsonSpeakCompletion(){
        loader.alpha = 0
       

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
        })
        
    }
    
    func watsonSpeakDialogCompletion(){
        self.loader.alpha = 0
        
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
            
            self.recordingButton.enabled = true
        })
        
    }
    
    func watsonSpeakNoAnimation(text: String){
        textToSpeech.synthesize(text,
                               audioFormat: AudioFormat.WAV,
                               failure: { error in
                                print("error was generated \(error)")
            })
        { data in
            
            do {
                
                self.audioPlayer = try AVAudioPlayer(data: data)
                self.audioPlayer?.delegate = self
                self.audioPlayer!.play()
                self.dropdownButton.hidden = true
                
            } catch {
                print("Couldn't create player.")
            }
        }

    }
    
    func watsonSpeak(text: String, fromDialog: Bool){
        
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
                    
                    let Delay = (self.audioPlayer?.duration)! * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                    let DispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Delay))
                    dispatch_after(DispatchTime, dispatch_get_main_queue(), {
                        if(fromDialog){
                            self.recordingButton.hidden = false
                            self.watsonTextView.text = ""
                            self.dropdownButton.hidden = false
                            self.dropdownButton.enabled = true
                        }
                        self.watsonSpeakCompletion()
                    })
                    
                } catch {
                    print("Couldn't create player.")
                }
            }
    }
    
    func AskDialogAndReturnAnswerAsString(input: String) -> Void{
        backButton.enabled = false
        refreshButton.enabled = false
        
        loader.alpha = 1
        
        var formattedInput = input.stringByReplacingOccurrencesOfString(" ", withString: "_")
        formattedInput = formattedInput.stringByReplacingOccurrencesOfString("\"", withString: "")

        let fullURL = dialogEndpoint + formattedInput
        
        // Create NSURL Ibject
        let getURL = NSURL(string: fullURL.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
        
        // Creaste URL Request
        let request = NSMutableURLRequest(URL: getURL!)
        
        // Set request HTTP method to GET. It could be POST as well
        request.HTTPMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        print("Sent ...")
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
            guard error == nil && data != nil else{
                // check for fundamental networking error
                print("error=\(error)")
                self.loader.alpha = 0
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {
                // check for http errors
                print("\r\nERROR: statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                
                self.watsonSpeak("Sorry I'm not quite sure what you said", fromDialog: true)
            }
            // Print out response string
            let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            
            let dialogOutput = responseString as! String
            
            print("dialogOutput = \(dialogOutput)")
            
            self.watsonSpeak(dialogOutput, fromDialog: true)
            
            let answerString: String! = responseString as! String
            dispatch_async(dispatch_get_main_queue(), {
                
                self.watsonTextView.text = answerString
    
            })
            
            self.loader.alpha = 0
        })
        
        task.resume()
        
    }

    
    @IBAction func backButtonTapped(sender: AnyObject) {
        playerCardView.hidden = true
        
        watsonTextView.text = ""
        clearWatsonTextViewButton.enabled = true
        dispatch_async(dispatch_get_main_queue(), {
            self.recordingButton.hidden = false
            self.dropdownButton.hidden = false
            self.dropdownButtonImage.hidden = false
        })
    
        backButton.hidden = true
        refreshButton.hidden = true
        
        prepareWatsonAnimation()
        showWatsonAnimation()
    }
    @IBAction func refreshButtonTapped(sender: AnyObject) {
        watsonSpeak(watsonTextView.text, fromDialog: false)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
    }
    
    func sendHTTPPostImage(image: String) -> Void{
        prepareLoaderAnimation()
        showLoaderAndStartAnimation()
        dropdownButton.hidden = true

        let request = NSMutableURLRequest(URL: NSURL(string: faceRecognitionEndpoint)!)
        request.HTTPMethod = "POST"
        
        let dict = ["image": image]
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(dict as NSDictionary, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: self, delegateQueue:NSOperationQueue.mainQueue())
        print("Sent ...")
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
            guard error == nil && data != nil else{                                                          // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? NSHTTPURLResponse where httpStatus.statusCode != 200 {           // check for http errors
                print("\r\nERROR: statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                
                self.watsonSpeak("Sorry I'm not quite sure who that is.", fromDialog: false)
            }
                
            else if let responseString = NSString(data: data!, encoding: NSUTF8StringEncoding){
                
                let jsonDict = self.convertStringToDictionary(responseString as String)
                let player_name = jsonDict!["response"]?["player_name"]
                let player_summary = jsonDict!["response"]?["player_summary"]
                let match_confidence = jsonDict!["response"]?["match_confidence"]
                let image = jsonDict!["response"]?["image"]
                let err = jsonDict!["response"]?["err"]
                let position = jsonDict!["response"]?["position"]
                let birth_date = jsonDict!["response"]?["birth_date"]
                let birth_place = jsonDict!["response"]?["birth_place"]
                let height = jsonDict!["response"]?["height"]
                let weight = jsonDict!["response"]?["weight"]
                let current_team = jsonDict!["response"]?["current_team"]
                let current_team_logo = jsonDict!["response"]?["team_logo"]

                if((err as! String) != ""){
                    self.watsonSpeak((err as! String), fromDialog: false)
                    print(err as! String)
                    self.watsonTextView.text = (err as! String)
                    self.recordingButton.hidden = false
                }
                else{
                    print(player_name as! String)
                    print(player_summary as! String)
                    print(match_confidence as! Double)
                
                    self.watsonTextView.text = "It looks to me like that is \(player_name as! String)"
                    self.watsonSpeakNoAnimation(self.watsonTextView.text)
                    
                    let answerString: String! = player_name as! String
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        let decodedData = NSData(base64EncodedString: image as! String, options: NSDataBase64DecodingOptions(rawValue: 0))
                        let decodedimage = UIImage(data: decodedData!)
                        self.playerHeadshotImageView.image = decodedimage! as UIImage
                        
                        if current_team_logo as! String != "NULL"{
                            let decodedLogoData = NSData(base64EncodedString: current_team_logo as! String, options: NSDataBase64DecodingOptions(rawValue: 0))
                            let decodedLogoImage = UIImage(data: decodedLogoData!)
                            self.playerCurrentTeamLogo.image = decodedLogoImage! as UIImage
                            self.playerCurrentTeamLabel.text = current_team as? String
                        }

                        self.playerCardView.hidden = false
                        self.playerNameLabel.text = player_name as? String
                        self.playerPosistionLabel.text = position as? String
                        self.playerBirthdayLabel.text = birth_date as? String
                        self.playerBirthplaceLabel.text = birth_place as? String
                        let heightWeight = (height as! String) + " " + (weight as! String)
                        self.playerHeightWeightLabel.text = heightWeight
                        self.playerSummaryTextView.text = player_summary as? String
                        
                        self.backButton.hidden = false
                        self.refreshButton.hidden = false
                        
                        self.playerCardView.layer.shadowColor = UIColor(white: 0.0, alpha: 0.5).CGColor
                        self.playerCardView.layer.shadowOffset = CGSizeMake(0.0, 0.0)
                        self.playerCardView.layer.shadowOpacity = 1.0
                        self.playerCardView.layer.shadowRadius = 6.0
                        self.playerCardView.layer.cornerRadius = 6.0

                    })
                }
                
            }
            self.dropdownButtonImage.hidden = true
            self.loader.alpha = 0
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

    
    func endStream() -> Void{
        stopStreamingDefault?()
        recordingButton.setImage(UIImage(named: "recording.png"), forState: UIControlState.Normal)
        isStreamingDefault = false
        playEndRecordingBeep()
        proccessSpeechAndFindKeywords()
        addEffectToButton()
    }
    
    func handleRecordingButtonTapped() -> Void{
        // stop if already streaming
        if (isStreamingDefault) {
            loader.alpha = 1
            endStream()
            return
        }
        
        dropdownButton.enabled = false
        watsonTextView.text = ""
        recordingButton.layer.removeAllAnimations()

        // set streaming
        isStreamingDefault = true
        
        // change button title
        recordingButton.setImage(UIImage(named: "stop.png"), forState: UIControlState.Normal)
        
        // configure settings for streaming
        var settings = TranscriptionSettings(contentType: .L16(rate: 44100, channels: 1))
        settings.continuous = true
        settings.inactivityTimeout = 1
        settings.interimResults = true
        
        let first_seconds = 0.02
        let first_delay = first_seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let first_dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(first_delay))
        dispatch_after(first_dispatchTime, dispatch_get_main_queue(), {
            
            self.stopStreamingDefault = speechToText.transcribe(settings, failure: nil) { results in
                self.showResults(results)
            }
            
            self.playStartRecordingBeep()
            self.prepareCloseWatson()
            self.showCloseWatson()
        })
        
        let seconds = 0.5
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.prepareAndShowRecordingWatson()
        })

    }
    
    @IBAction func recordingButtonTapped(sender: AnyObject) {
        dispatch_after(0, dispatch_get_main_queue(), {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        })
        handleRecordingButtonTapped()
    }
    
    func failureDefault(error: NSError) {
        let title = "Speech to Text Error:\nStreaming (Default)"
        let message = error.localizedDescription
        
        if message.containsString("inactivity"){
            return
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in
            self.self.endStream()
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
                text += "\"" + String(title.characters.dropLast()) + "\""
                
                watsonTextView.text = text
                loader.alpha = 0
                
                if (isStreamingDefault) {
                    loader.alpha = 1
                    endStream()
                    return
                }
            }
        }
        
        if results.last?.final == false {
            if let transcript = results.last?.alternatives.last?.transcript {
                text += titleCase(transcript)
            }
            watsonTextView.text = text
        }
        
        print(text)
    }
    
    func titleCase(s: String) -> String {
        let first = String(s.characters.prefix(1)).uppercaseString
        return first + String(s.characters.dropFirst())
    }
    
    func failure(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default) { action in }
        alert.addAction(ok)
        presentViewController(alert, animated: true) { }
    }
}

