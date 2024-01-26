//
//  RecentViewController.swift
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

//-------------------------------------------------------
class RecentItem {
    
    // MARK: Properties
    var text: String = ""
    var fileID: UInt32
    var maleFileID: UInt32
    var femaleFileID: UInt32
    var rate: Int = 0
    var fileURL: String = ""
    
    // MARK: Initialization
    init?(text: String, fileID: UInt32, maleFileID: UInt32, femaleFileID: UInt32, rate: Int, url: String) {
        // Initialize stored properties.
        self.text = text
        self.fileID = fileID
        self.maleFileID = maleFileID
        self.femaleFileID = femaleFileID
        self.rate = rate
        self.fileURL = url
    }
}

var recents = [RecentItem]()

//-------------------------------------------------------
class RecentItemsViewCell: UITableViewCell{
    
    // MARK: Properties

    @IBOutlet var CellLabel: UILabel!
    @IBOutlet weak var LikedImage: UIImageView!
    @IBOutlet weak var DislikedImage: UIImageView!

    //-------------------------------------------------------
    override func didAddSubview(_ subview: UIView) {
        if subview.tag == 111 {
            subview.isHidden = false
            subview.backgroundColor = UIColor(red: 0, green: 122/255, blue: 255/255, alpha: 1)
            let initialXOrigin = self.bounds.origin.x
            UIView.animate(withDuration: 0.3 , animations : {
                self.bounds.origin.x = 25
                }, completion: { finished in
                    UIView.animate (withDuration: 0.3 , animations : {
                        self.bounds.origin.x = initialXOrigin
                        }, completion: { finished in
                            subview.removeFromSuperview()
                    })
            })
        }
    }
}

//-------------------------------------------------------
class RecentViewController: UIViewController, UITableViewDelegate {
    
    var isSwipeShown = false
    
    // MARK: Properties
   //-------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralController.recentFilesViewController = self
        RecentItemsTable.delegate = self
        RecentItemsTable.rowHeight = UITableViewAutomaticDimension
        RecentItemsTable.estimatedRowHeight = 140
        RecentItemsTable.reloadData()
    }
    
    //-------------------------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.navigationItem.title="Recent Jokes"
        if recents.isEmpty != true{
            if recents[0].text.isEmpty == true || (recents.count > 1 && recents[1].text.isEmpty){
                centralController.cloundService.updateJokes(jokes: recents){ (success, response) -> Void in
                    if success != true {
                        #if DEBUG
                            print ("ERROR: RecentViewController: Error processing last 10 played = ", response)
                        #endif
                        DispatchQueue.main.async{
                            recents.removeAll()
                            self.RecentItemsTable.reloadData()
                            centralController.getLast10Played()
                        }
                    } else {
                        #if DEBUG
                            print ("DBG: RecentViewController: 10 Last played updated")
                        #endif
                        recents = response!
                        DispatchQueue.main.async{
                            centralController.myToyViewController?.lastPlayedDidChange(recents[0])
                            self.RecentItemsTable.reloadData()
                        }
                    }
                }
            } else {
                RecentItemsTable.reloadData()
            }
        }
    }
    
    //-------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if recents.isEmpty == true || isSwipeShown == true {
            return
        }
        
        var row = 0
        if recents.count > 2 {
            row = 2
        }
        
        guard let cell = RecentItemsTable.cellForRow(at: NSIndexPath(row: row, section: 0) as IndexPath)
            else { return }
        
        animateSwipe(cell: cell)
        isSwipeShown = true
        
    }
    
    //-------------------------------------------------------
    @IBOutlet var RecentItemsTable: UITableView!
    
    //-----------------------------------
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell : UITableViewCell = tableView.cellForRow(at: indexPath)
            else {return}
        
        animateSwipe(cell: cell)
    }
    
    //-----------------------------------
    func animateSwipe (cell: UITableViewCell) {
        let swipeLabel : UILabel = UILabel.init(frame: CGRect.init(x: cell.bounds.size.width, y: 0, width: 25, height: cell.bounds.size.height))
        swipeLabel.tag = 111
        cell.addSubview(swipeLabel)
    }
    
    
    //-----------------------------------
    @objc(tableView:canFocusRowAtIndexPath:) func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        // the cells you would like the actions to appear needs to be editable
        return true
    }
    
    //-----------------------------------
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if recents[(indexPath as NSIndexPath).row].fileURL.isEmpty == false {
            let play = UITableViewRowAction(style: .normal, title: " Play ") { action, index in
                let silentStatus = centralController.isSilent()
                if silentStatus == 0 {
                    centralController.playFile(recents[(indexPath as NSIndexPath).row])
                } else if silentStatus == 1 {
                    self.displayPlayFileAlertMessage("The Sound Volume was set to its minimum position. Please increase Sound Volume to play the joke.")
                } else {
                    self.displayPlayChoiceMessage(silentStatus, file: (indexPath as NSIndexPath).row)
                }
                tableView.setEditing(false, animated: true)
            }
            play.backgroundColor = UIColor(red: 0, green: 122/255, blue: 255/255, alpha: 1)
            
            let share = UITableViewRowAction(style: .normal, title: "Share") { action, index in
                let recent = recents[(indexPath as NSIndexPath).row]
                self.displayMyAlertMessage(recent.fileURL, text: recent.text)
                tableView.setEditing(false, animated: true)
            }
            share.backgroundColor = UIColor(red: 255/255, green: 45/255, blue: 55/255, alpha: 1)
            
            let rate = UITableViewRowAction(style: .normal, title: " Rate ") { action, index in
                self.displayRateAlertMessage(recents[(indexPath as NSIndexPath).row].fileID, index: (indexPath as NSIndexPath).row)
                tableView.setEditing(false, animated: true)
            }
            rate.backgroundColor = UIColor(red: 76/255, green: 217/255, blue: 64/255, alpha: 1)
            
            return [play, share, rate]
        } else {
            let play = UITableViewRowAction(style: .normal, title: " Play ") { action, index in
                centralController.playFile(recents[(indexPath as NSIndexPath).row])
                tableView.setEditing(false, animated: true)
            }
            play.backgroundColor = UIColor(red: 0, green: 122/255, blue: 255/255, alpha: 1)
            return [play]
        }
    }
    
    //----------------------------------------------------
    func displayPlayFileAlertMessage(_ userMessage:String)
    {
        let myAlert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil);
        myAlert.addAction(okAction);
        self.present(myAlert , animated: true, completion: nil)
    }
    
    //----------------------------------------------------
    func displayPlayChoiceMessage(_ id: Int, file: Int)
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
            print(file)
            centralController.playFile(recents[file])
        }
        myAlert.addAction(playAction);
        
        self.present(myAlert , animated: true, completion: nil)
    }
    
    //-----------------------------------
    @objc(tableView:commitEditingStyle:forRowAtIndexPath:) func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
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
        content.contentTitle = "Joke from my KiQ Toy"
        content.contentDescription = text
        FBSDKShareDialog.show(from: self, with: content, delegate: nil)
    }

    
    //----------------------------------------------------
    func displayMyAlertMessage(_ url: String, text: String)
    {
        let myAlert = UIAlertController(title: "Share this joke on", message: "", preferredStyle: UIAlertControllerStyle.actionSheet);
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        myAlert.addAction(cancelAction)
        
        myAlert.view.tintColor = UIColor(red: 137/255, green: 29/255, blue: 36/255, alpha: 1)
        let twitterAction = UIAlertAction(title: "Twitter", style: UIAlertActionStyle.default) { action -> Void in
            self.postOnTwitter(text)
        }
        myAlert.addAction(twitterAction);
        
        myAlert.view.tintColor = UIColor(red: 137/255, green: 29/255, blue: 36/255, alpha: 1)
        let facebookAction = UIAlertAction(title: "Facebook", style: UIAlertActionStyle.default) { action -> Void in
            self.postOnFacebook(url, text: text)
        }
        myAlert.addAction(facebookAction);
        
        self.present(myAlert , animated: true, completion: nil)
    }
    
    //----------------------------------------------------
    func displayRateAlertMessage(_ id: UInt32, index: Int)
    {
        let myAlert = UIAlertController(title: "Rate this joke", message: "", preferredStyle: UIAlertControllerStyle.actionSheet);
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        myAlert.addAction(cancelAction)
        
        myAlert.view.tintColor = UIColor(red: 137/255, green: 29/255, blue: 36/255, alpha: 1)
        let twitterAction = UIAlertAction(title: "Like", style: UIAlertActionStyle.default) { action -> Void in
            centralController.cloundService.likeJoke(id, liked: true) { (success) -> Void in
                if success == true {
                    recents[index].rate = 1
                    self.RecentItemsTable.reloadData()
                    if index == 0 {
                        centralController.myToyViewController?.LikeButton.setTitle("LIKED", for: UIControlState())
                        centralController.myToyViewController?.DislikeButton.setTitle("DISLIKE", for: UIControlState())
                        centralController.myToyViewController?.LikedCatPicture.isHidden = false
                        centralController.myToyViewController?.DislikedCatPicture.isHidden = true
                    }

                }
            }
        }
        myAlert.addAction(twitterAction);
        
        myAlert.view.tintColor = UIColor(red: 137/255, green: 29/255, blue: 36/255, alpha: 1)
        let facebookAction = UIAlertAction(title: "Dislike", style: UIAlertActionStyle.default) { action -> Void in
            centralController.cloundService.likeJoke(id, liked: false) { (success) -> Void in
                if success == true {
                    recents[index].rate = -1
                    self.RecentItemsTable.reloadData()
                    if index == 0 {
                        centralController.myToyViewController?.LikeButton.setTitle("LIKE", for: UIControlState())
                        centralController.myToyViewController?.DislikeButton.setTitle("DISLIKED", for: UIControlState())
                        centralController.myToyViewController?.LikedCatPicture.isHidden = true
                        centralController.myToyViewController?.DislikedCatPicture.isHidden = false
                    }
                }
            }
        }
        myAlert.addAction(facebookAction);
        
        self.present(myAlert , animated: true, completion: nil)
    }
    
}


// MARK: Table View Data Source
//-------------------------------------
extension RecentViewController: UITableViewDataSource {
    //-------------------------------------------------------
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    //-------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if recents.isEmpty == true {
            return 1
        }
        return recents.count
    }
    
    //-------------------------------------------------------
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentItemsViewCell", for: indexPath) as! RecentItemsViewCell
        if recents.isEmpty != true {
            let recent = recents[(indexPath as NSIndexPath).row]
            cell.CellLabel.text = "    \"" + recent.text + "\""
            if recent.rate == 1 {
                cell.LikedImage.isHidden = false
                cell.DislikedImage.isHidden = true
            } else if recent.rate == -1 {
                cell.LikedImage.isHidden = true
                cell.DislikedImage.isHidden = false
            } else {
                cell.LikedImage.isHidden = true
                cell.DislikedImage.isHidden = true
            }
        } else if (indexPath as NSIndexPath).row == 0 {
            cell.CellLabel.text = "Fetching data from toy...."
        }
        return cell
    }
}
