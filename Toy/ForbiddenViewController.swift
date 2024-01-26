//
//  ForbiddenViewController.swift
//  Toy
//
//  Created by Maxim Kitaygora on 6/8/16.
//  Copyright © 2016 Signe Networks. All rights reserved.
//

import Foundation
import UIKit


//-------------------------------------------------------
class ForbiddenItem {
    
    // MARK: Properties
    var id:     Int = 0
    var text:   String = ""
    var on:     Bool = true
    var bit:    Int = 0
    
    // MARK: Initialization
    init?(id: Int, text: String, on: Bool, bit: Int) {
        // Initialize stored properties.
        self.text = text
        self.on = on
        self.id = id
        self.bit = bit
    }
}

//-------------------------------------------------------
class ForbiddenItemViewCell: UITableViewCell{
    
    // MARK: Properties
    @IBOutlet weak var TextLabel: UILabel!
    @IBOutlet weak var StatusSwitch: UISwitch!
    
}

//-------------------------------------------------------
class ForbiddenTableViewController: UITableViewController {
    
    // MARK: Properties
    //-------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.reloadData()
    }
    
    //-------------------------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    //-------------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //-------------------------------------------------------
    @IBAction func settingDidChange(_ sender: AnyObject) {
        let settingSwitch : UISwitch = sender as! UISwitch
        centralController.sessionSettings.toyProfile.forbiddenContent[settingSwitch.tag].on = settingSwitch.isOn
        centralController.generalSettingDidChange()
    }
    
    //-------------------------------------------------------
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //-------------------------------------------------------
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //-------------------------------------------------------
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return centralController.sessionSettings.toyProfile.forbiddenContent.count
    }
    
    //-------------------------------------------------------
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ForbiddenItemViewCell", for: indexPath) as! ForbiddenItemViewCell
        let forbiddenItem = centralController.sessionSettings.toyProfile.forbiddenContent[(indexPath as NSIndexPath).row]
        cell.TextLabel.text = forbiddenItem.text
        cell.StatusSwitch.isOn = forbiddenItem.on
        cell.StatusSwitch.tag = (indexPath as NSIndexPath).row
        return cell
    }
}

