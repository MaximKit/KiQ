//
//  MyToyViewController.swift
//  Toy
//
//  Created by Maxim Kitaygora on 1/21/16.
//  Copyright © 2016 Signe Networks. All rights reserved.
//

import Foundation
import UIKit
import Social
import FBSDKCoreKit
import FBSDKShareKit

//------------------------------------
extension UILabel {
    func setFontSize (_ sizeFont: CGFloat) {
        self.font =  UIFont(name: "Comic Neue", size: sizeFont)!
        self.sizeToFit()
    }
}

//------------------------------------
extension UIButton {
    func setFontSize (_ sizeFont: CGFloat) {
        self.titleLabel!.font =  UIFont(name: "Comic Neue", size: sizeFont)
        self.sizeToFit()
    }
}


//------------------------------------
class MyToyViewController: UIViewController {
   
    var playFileTimer: Timer?
    
    //-------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenSize: CGRect = UIScreen.main.bounds
        centralController.myToyViewController = self
        
        switch screenSize.height {
            
        case 480:  //iPhone 4S
            break
        case 568:  //iPhone 5S
            ToyPictureHeigh.constant = 170
            ToyViewBottomPosition.constant = -85
            LikeButton.setFontSize(17)
            DislikeButton.setFontSize(17)
            ConnectAnotherButton.setFontSize(17)
            CentralMessageLabel.setFontSize(18)
            break
        default:
            ToyViewBottomPosition.constant = -120
            ToyPictureHeigh.constant = 220
            LikeButton.setFontSize(20)
            DislikeButton.setFontSize(20)
            ConnectAnotherButton.setFontSize(20)
            CentralMessageLabel.setFontSize(20)
            break
        }
        
        FacebookBtnConstraint.constant = screenSize.width / 4
        TwitterBtnConstraint.constant = screenSize.width / 4
        DislikeButton.titleLabel!.textAlignment = NSTextAlignment.center
        DislikeButton.layer.cornerRadius = 10
        LikeButton.titleLabel!.textAlignment = NSTextAlignment.center
        LikeButton.layer.cornerRadius = 10
        ConnectAnotherButton.layer.cornerRadius = 10

        resetMainScreen()
        UITabBar.appearance().tintColor = MY_PINK_COLOR
    }
    
    //-----------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if centralController.toyStatus == ToyStatus.searching{
            bleDidChange(true)
            if centralController.expectedToyID != "" && centralController.cloundService.isCloudSessionEnabled() == true{
                self.ConnectAnotherButton.isHidden = false
            }
        } else if centralController.toyStatus == ToyStatus.disconnected {
            upgradeDidChange(false, progress: 0)
        }
        
        if centralController.isSilent() == 1 || centralController.isSilent() == 2 {
                CatPicture.image = UIImage(named: "BigCatSilent")
        } else {
                CatPicture.image = UIImage(named: "BigCat")
        }
        self.tabBarController?.navigationItem.title="My KiQ"
    }
    
    //-----------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //-----------------------------------------
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //--------------------------------------------------------
    // MARK: Outlets
    @IBOutlet var CentralMessageLabel: UILabel!
    @IBOutlet var DislikeButton: UIButton!
    @IBOutlet var LikeButton: UIButton!
    @IBOutlet var PlayButton: UIButton!
    @IBOutlet var TwitterShareButton: UIButton!
    @IBOutlet var CatPicture: UIImageView!
    @IBOutlet weak var CatNoPowerPicture: UIImageView!
    @IBOutlet weak var CatOnBackPicture: UIImageView!
    @IBOutlet var ToyMessageHeigh: NSLayoutConstraint!
    @IBOutlet var ToyPictureHeigh: NSLayoutConstraint!
    @IBOutlet var ToyViewBottomPosition: NSLayoutConstraint!
    @IBOutlet var FetchingDataIndicator: UIActivityIndicatorView!
    @IBOutlet var FacebookBtnConstraint: NSLayoutConstraint!
    @IBOutlet var TwitterBtnConstraint: NSLayoutConstraint!
    @IBOutlet var FacebookShareButton: UIButton!
    @IBOutlet weak var ConnectAnotherButton: UIButton!
    @IBOutlet weak var LikedCatPicture: UIImageView!
    @IBOutlet weak var DislikedCatPicture: UIImageView!
    @IBOutlet weak var BatteryView: UIImageView!
    @IBOutlet weak var batteryViewWidth: NSLayoutConstraint!
    @IBOutlet weak var batteryViewAspect: NSLayoutConstraint!
    @IBOutlet weak var FlashPicture: UIImageView!
    @IBOutlet weak var UpgradeProgressIndicator: UIProgressView!
    @IBOutlet weak var ConnectedWiFi: UILabel!

    //--------------------------------------------------------
    // MARK: Outlets Actions
    //--------------------------------------------------------
    @IBAction func connectAnotherTapped(_ sender: AnyObject) {
        #if DEBUG
            print("DBG: connectAnotherToy: -> .Idle -> .Searching")
        #endif
        centralController.toyStatus = ToyStatus.disconnected
        centralController.expectedToyID = ""
        centralController.toyStatus = ToyStatus.searching
    }
    
    //--------------------------------------------------------
    @IBAction func playButtonTapped(_ sender: AnyObject) {
        if !recents.isEmpty {
            let silentStatus = centralController.isSilent()
            if silentStatus == 0 {
                centralController.playFile(recents[0])
                self.playFileTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(playFileTimeout), userInfo: nil, repeats: false)
                PlayButton.isEnabled = false
            } else if silentStatus == 1 {
                displayMyAlertMessage("The Sound Volume was set to its minimum position. Please increase Sound Volume to play the joke.")
            } else {
                displayPlayChoiceMessage(silentStatus)
            }
        }
    }
    //--------------------------------------------------------
    @IBAction func likeButtonTapped(_ sender: AnyObject) {
        if recents[0].fileURL.isEmpty != true {
            self.LikeButton.isUserInteractionEnabled = false
            self.DislikeButton.isUserInteractionEnabled = false
            FetchingDataIndicator.startAnimating()
            centralController.cloundService.likeJoke(recents[0].fileID, liked: true) { (success) -> Void in
                DispatchQueue.main.async{
                    self.DislikeButton.isUserInteractionEnabled = true
                    self.FetchingDataIndicator.stopAnimating()
                    if success == true {
                        self.LikeButton.setTitle("LIKED", for: UIControlState())
                        self.DislikeButton.setTitle("DISLIKE", for: UIControlState())
                        self.LikedCatPicture.isHidden = false
                        self.DislikedCatPicture.isHidden = true
                        recents[0].rate = 1
                    }
                }
            }
        }
    }
    //--------------------------------------------------------
    @IBAction func dislikeButtonTapped(_ sender: AnyObject) {
        if recents[0].fileURL.isEmpty != true {
            LikeButton.isUserInteractionEnabled = false
            DislikeButton.isUserInteractionEnabled = false
            FetchingDataIndicator.startAnimating()
            centralController.cloundService.likeJoke(recents[0].fileID, liked: false){ (success) -> Void in
                DispatchQueue.main.async{
                    self.LikeButton.isUserInteractionEnabled = true
                    self.FetchingDataIndicator.stopAnimating()
                    if success == true {
                        self.LikeButton.setTitle("LIKE", for: UIControlState())
                        self.DislikeButton.setTitle("DISLIKED", for: UIControlState())
                        self.LikedCatPicture.isHidden = true
                        self.DislikedCatPicture.isHidden = false
                        recents[0].rate = -1
                    }
                }
            }
        }
    }
    //--------------------------------------------------------
    @IBAction func shareOnTwitter(_ sender: AnyObject) {
        if recents[0].fileURL.isEmpty == false {
            postOnTwitter(CentralMessageLabel.text!)
        } else {
            displayMyAlertMessage("Sorry. We can not share this joke on Twitter :(")
        }
    }
    //--------------------------------------------------------
    @IBAction func shareOnFacebook(_ sender: AnyObject) {
        if recents[0].fileURL.isEmpty == false {
            postOnFacebook(recents[0].fileURL, text: CentralMessageLabel.text!)
        } else {
            displayMyAlertMessage("Sorry. We can not share this joke on Facebook :(")
        }
    }
    
    //--------------------------------------------------------
    // MARK: Functions
    //--------------------------------------------------------
    func bleDidChange(_ inProgress: Bool){
        DispatchQueue.main.async{
            self.UpgradeProgressIndicator.isHidden = true
            self.ConnectedWiFi.isHidden = true
            self.CentralMessageLabel.text = centralController.upperStatusLabel + "\n\n" + centralController.lowerStatusLabel
            if inProgress == true {
                self.FetchingDataIndicator.startAnimating()
            } else {
                self.DislikeButton.isHidden = true
                self.LikeButton.isHidden = true
                self.TwitterShareButton.isHidden = true
                self.FacebookShareButton.isHidden = true
                self.LikedCatPicture.isHidden = true
                self.DislikedCatPicture.isHidden = true
                self.BatteryView.isHidden = true
                self.FlashPicture.isHidden = true
                self.CatPicture.isHidden = false
                self.CatNoPowerPicture.isHidden = true
                self.CatOnBackPicture.isHidden = true
                self.FetchingDataIndicator.stopAnimating()
            }
        }
    }
    
    //--------------------------------------------------------
    func cloudDidChange(_ inProgress: Bool){
        CentralMessageLabel.text = centralController.upperStatusLabel + "\n\n" + centralController.lowerStatusLabel
        if inProgress == true {
            FetchingDataIndicator.startAnimating()
        } else {
            DislikeButton.isHidden = true
            LikeButton.isHidden = true
            TwitterShareButton.isHidden = true
            FacebookShareButton.isHidden = true
            LikedCatPicture.isHidden = true
            DislikedCatPicture.isHidden = true
            if centralController.toyStatus == ToyStatus.connected || centralController.toyStatus == ToyStatus.disconnected {
                FetchingDataIndicator.stopAnimating()
            }
        }
    }
    
    //--------------------------------------------------------
    func upgradeDidChange(_ inProgress: Bool, progress: Float){
        DispatchQueue.main.async{
            self.CentralMessageLabel.text = centralController.upperStatusLabel + "\n\n" + centralController.lowerStatusLabel
            if inProgress == true {
                if progress != 0 {
                    self.UpgradeProgressIndicator.progress = progress
                    self.UpgradeProgressIndicator.isHidden = false
                    self.FetchingDataIndicator.stopAnimating()
                } else {
                    self.UpgradeProgressIndicator.isHidden = true
                    self.FetchingDataIndicator.startAnimating()
                }
                self.DislikeButton.isHidden = true
                self.LikeButton.isHidden = true
                self.TwitterShareButton.isHidden = true
                self.FacebookShareButton.isHidden = true
                self.LikedCatPicture.isHidden = true
                self.DislikedCatPicture.isHidden = true
                self.BatteryView.isHidden = true
                self.FlashPicture.isHidden = true
                self.CatPicture.isHidden = false
                self.CatNoPowerPicture.isHidden = true
                self.CatOnBackPicture.isHidden = true
                self.PlayButton.isHidden = true
            } else {
                self.ConnectedWiFi.isHidden = true
                self.UpgradeProgressIndicator.isHidden = true
                self.UpgradeProgressIndicator.progress = 0
                self.FetchingDataIndicator.stopAnimating()
            }
        }
    }

    //--------------------------------------------------------
    func lastPlayedDidChange(_ joke: RecentItem){
        DispatchQueue.main.async{
            if joke.fileURL.isEmpty == false {
                self.DislikeButton.isHidden = false
                self.LikeButton.isHidden = false
                self.PlayButton.isHidden = false
                self.TwitterShareButton.isHidden = false
                self.FacebookShareButton.isHidden = false
            }
            self.CentralMessageLabel.text = "\"" + joke.text + "\""
            self.FetchingDataIndicator.stopAnimating()
        }
    }
    
    //--------------------------------------------------------
    func toyStatusDidChange(batteryLevel: UInt8, isCharging: Bool, isSilent: Bool){
        var imageSize = BatteryView.image?.size
        var toyBatteryLevel: UInt8 = 1
        BatteryView.isHidden = false
        toyBatteryLevel = batteryLevel
        if imageSize != nil {
            CatOnBackPicture.isHidden = !isSilent
            CatPicture.isHidden = isSilent
            if toyBatteryLevel <= 20 && isCharging == false{
                CatPicture.isHidden = true
                CatOnBackPicture.isHidden = true
                CatNoPowerPicture.isHidden = false
            }
            FlashPicture.isHidden = !isCharging

            imageSize?.width = (batteryViewWidth.constant - 4) * CGFloat(toyBatteryLevel)/100
            imageSize?.height = batteryViewWidth.constant / batteryViewAspect.multiplier - 2
            
            let lastView = BatteryView.subviews.last
            lastView?.removeFromSuperview()
            let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 1, y: 1), size: imageSize!))
            BatteryView.addSubview(imageView)
            guard let image = drawCustomImage(imageSize!, toyBatteryLevel: toyBatteryLevel)
                else {return}
            imageView.image = image
        }
    }
    
    //--------------------------------------------------------
    func resetInProgress(){
        DispatchQueue.main.async{
            self.CentralMessageLabel.text = centralController.upperStatusLabel + "\n\n" + centralController.lowerStatusLabel
            self.DislikeButton.isHidden = true
            self.LikeButton.isHidden = true
            self.TwitterShareButton.isHidden = true
            self.FacebookShareButton.isHidden = true
            self.LikedCatPicture.isHidden = true
            self.DislikedCatPicture.isHidden = true
            self.BatteryView.isHidden = true
            self.FlashPicture.isHidden = true
            self.CatPicture.isHidden = false
            self.CatNoPowerPicture.isHidden = true
            self.CatOnBackPicture.isHidden = true
            self.FetchingDataIndicator.startAnimating()
        }
    }
    
    //--------------------------------------------------------
    func toyDisconnected(){
        DispatchQueue.main.async{
            self.CentralMessageLabel.text = "Toy Disconnected" + "\n\n"
            self.DislikeButton.isHidden = true
            self.LikeButton.isHidden = true
            self.TwitterShareButton.isHidden = true
            self.FacebookShareButton.isHidden = true
            self.LikedCatPicture.isHidden = true
            self.DislikedCatPicture.isHidden = true
            self.BatteryView.isHidden = true
            self.FlashPicture.isHidden = true
            self.CatPicture.isHidden = false
            self.CatNoPowerPicture.isHidden = true
            self.CatOnBackPicture.isHidden = true
            self.FetchingDataIndicator.stopAnimating()
        }
    }
        
    //--------------------------------------------------------
    func resetMainScreen(){
        CentralMessageLabel.text = ""
        DislikeButton.isHidden = true
        LikeButton.isHidden = true
        PlayButton.isHidden = true
        TwitterShareButton.isHidden = true
        FacebookShareButton.isHidden = true
        LikedCatPicture.isHidden = true
        DislikedCatPicture.isHidden = true
        FlashPicture.isHidden = true
        BatteryView.isHidden = true
        CatPicture.isHidden = false
        CatNoPowerPicture.isHidden = true
        CatOnBackPicture.isHidden = true
    }
    
    // MARK: SocialFunctions
    // ----- Twitter --------------------------------
    func postOnTwitter(_ text: String)
    {
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter){
            let twitterController:SLComposeViewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
            let preparedText = prepareForTwitter(text)
            twitterController.setInitialText("#KiqToy: " + preparedText)
            twitterController.view.tintColor = UIColor(red: 137/255, green: 29/255, blue: 36/255, alpha: 1)
            self.present(twitterController, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Twitter Account", message: "Please login to your Twitter account.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            alert.view.tintColor = UIColor(red: 137/255, green: 29/255, blue: 36/255, alpha: 1)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // ----- Facebook --------------------------------
    func postOnFacebook(_ url: String, text: String)
    {
        let content : FBSDKShareLinkContent = FBSDKShareLinkContent()
        content.contentURL = URL(string: url)
        content.contentTitle = "Joke from my KiqToy"
        content.contentDescription = text
        FBSDKShareDialog.show(from: self, with: content, delegate: nil)
    }
    
    //----------------------------------------------------------
    func drawCustomImage(_ size: CGSize, toyBatteryLevel: UInt8) -> UIImage? {
        // Setup our context
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        let opaque = false
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        guard let context = UIGraphicsGetCurrentContext()
            else {return nil}
        
        if toyBatteryLevel > 20 {
            context.setFillColor(MY_GREEN_COLOR.cgColor)
        } else {
            context.setFillColor(MY_RED_COLOR.cgColor)
        }
        context.fill(bounds)
        
        // Drawing complete, retrieve the finished image and cleanup
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    //----------------------------------------------------
    func displayMyAlertMessage(_ userMessage:String)
    {
        if isModal() == true {
            let myAlert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert);
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil);
            myAlert.addAction(okAction);
            self.present(myAlert , animated: true, completion: nil)
        }
    }
    
    
     //----------------------------------------------------
     func isModal() -> Bool {
         if self.presentingViewController != nil {
            return true
         }
         
         if self.presentingViewController?.presentedViewController == self {
            return true
         }
         
         if self.navigationController?.presentingViewController?.presentedViewController == self.navigationController  {
            return true
         }
         
         if self.tabBarController?.presentingViewController is UITabBarController {
            return true
         }
         
         return false
     }
    
    //------------ Timer Callbacks -----------------------------
    //----------------------------------------------------------
    func playFileTimeout () {
        playFileTimer?.invalidate()
        PlayButton.isEnabled = true
    }
    //----------------------------------------------------
    func displayPlayChoiceMessage(_ id: Int)
    {
        var title = "Your KiQ is in Do Not Disturb mode"
        if id == 3 {
            title = "Your KiQ is in Silent mode"
        }
        let myAlert = UIAlertController(title: title, message: "Do you really want to play this joke?", preferredStyle: UIAlertControllerStyle.actionSheet);
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        myAlert.addAction(cancelAction)
        
        myAlert.view.tintColor = UIColor(red: 137/255, green: 29/255, blue: 36/255, alpha: 1)
        let playAction = UIAlertAction(title: "Play", style: UIAlertActionStyle.default) { action -> Void in
            centralController.playFile(recents[0])
            self.playFileTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.playFileTimeout), userInfo: nil, repeats: false)
            self.PlayButton.isEnabled = false
        }
        myAlert.addAction(playAction);
        
        self.present(myAlert , animated: true, completion: nil)
    }
    
}

//----------------------------------------------------
//Twitter shortener
func prepareForTwitter(_ text: String) -> String{
    
    var result : String = text
    let dict : Dictionary = [
        "@": "at",
        "you": "u",
        "You": "U",
        "be": "b",
        "Be": "B",
        "Because": "Coz",
        "because": "coz",
        "see": "c",
        "See": "C",
        "favorite": "fav",
        "Favorite": "Fav",
        "problem": "prob",
        "Problem": "Prob",
        "The": "Da",
        "the": "da",
        "Does": "Duz",
        "does": "duz",
        "And": "&",
        "and": "&",
        "One": "1",
        "one": "1",
        "To": "2",
        "to": "2",
        "Two": "2",
        "two": "2",
        "Three": "3",
        "three": "3",
        "for": "4",
        "For": "4",
        "four": "4",
        "Four": "4",
        "forever": "4rever",
        "Forever": "4rever",
        "Five": "5",
        "five": "5",
        "Six": "6",
        "six": "6",
        "Seven": "7",
        "seven": "7",
        "Eight": "8",
        "eight": "8",
        "nine": "9",
        "Nine": "9",
        "What": "wat",
        "what": "wat",
        "When": "Wn",
        "when": "wn",
        "Why": "Y",
        "why": "y",
        "Love": "Luv",
        "love": "luv",
        "Facebook": "FB",
        "Forward": "Fwd",
        "forward": "fwd",
        "Before": "B4re",
        "before": "b4re"
    ]
    for (source, destination) in dict {
        result = result.replacingOccurrences(of: source + " ", with: destination + " ")
        result = result.replacingOccurrences(of: " " + source, with: " " + destination)
        if result.characters.count < 132 {
            return result
        }
    }
    return result
}
