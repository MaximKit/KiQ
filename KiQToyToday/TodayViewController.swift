//
//  TodayViewController.swift
//  KiQToyToday
//
//  Created by Maxim Kitaygora on 9/29/16.
//  Copyright © 2016 Signe Networks. All rights reserved.
//

import UIKit
import CoreBluetooth
import NotificationCenter

// ------- Extension to simplify working with NSData --------------------------------------
extension NSData {
    var i8s:[Int8] { // Array of UInt8, Swift byte array basically
        var buffer:[Int8] = [Int8](repeating: 0, count: self.length)
        self.getBytes(&buffer, length: self.length)
        return buffer
    }
    
    var u8s:[UInt8] { // Array of UInt8, Swift byte array basically
        var buffer:[UInt8] = [UInt8](repeating: 0, count: self.length)
        self.getBytes(&buffer, length: self.length)
        return buffer
    }
    
    var u16s:[UInt16] { // Array of UInt16, Swift byte array basically
        var buffer:[UInt16] = [UInt16](repeating: 0, count: self.length / 2)
        self.getBytes(&buffer, length: (self.length / 2 * 2))
        return buffer
    }
    
    var u32s:[UInt32] { // Array of UInt32, Swift byte array basically
        var buffer:[UInt32] = [UInt32](repeating: 0, count: self.length / 4)
        self.getBytes(&buffer, length: (self.length / 4) * 4 )
        return buffer
    }
    
    var utf8:String? {
        return String(data: self as Data, encoding: String.Encoding.utf8)
    }
}

// BLE Status ---------------------------------------------------------------------
enum BLEStatus{
    case on
    case off
}

// App BLE Status -----------------------------------------------------------------
enum ToyStatus {
    case disconnected
    case searching
    case connected
    case upgrading
    case resetting
}

let HS_SERV_ADV_UUID      = CBUUID(string: "0040")
let HS_SERVICE_UUID       = CBUUID(string: "00000040-1212-EFDE-1523-785FEABCD123")
let HS_CLIENTINFO_C       = CBUUID(string: "00000041-1212-EFDE-1523-785FEABCD123")
let HS_DEVICEINFO_C       = CBUUID(string: "00000042-1212-EFDE-1523-785FEABCD123")
let HS_CONFIRMSERV_C      = CBUUID(string: "00000043-1212-EFDE-1523-785FEABCD123")

// Content -----------------------------------------------------------------------
let CONTENT_SERVICE_UUID  = CBUUID(string: "00000020-1212-EFDE-1523-785FEABCD123")
let CONT_PLAYFYLE_C       = CBUUID(string: "00000021-1212-EFDE-1523-785FEABCD123")
let CONT_FILESPLAYED_C    = CBUUID(string: "00000022-1212-EFDE-1523-785FEABCD123")

struct ContentCharxs {
    var playFileCharx:   CBCharacteristic?
    var lastPlaiedCharx: CBCharacteristic?
}

// Settings ----------------------------------------------------------------------
let SETUP_SERVICE_UUID      = CBUUID(string: "00000030-1212-EFDE-1523-785FEABCD123")
let SETUP_VOICE_C           = CBUUID(string: "00000031-1212-EFDE-1523-785FEABCD123")
let SETUP_STATUS_C          = CBUUID(string: "00000033-1212-EFDE-1523-785FEABCD123")

struct SetupCharxs {
    var volumeCharx:    CBCharacteristic?
    var statusCharx:    CBCharacteristic?
}

// Status representing BLE connection status --------------------------------------
enum BLEConnectionStatus {
    case paired
    case clientIdSent
    case connecting
}

// All suplimentary characteristics -----------------------------------------------
struct ToySupplimentaryCharx {
    var setup:               SetupCharxs
    var content:             ContentCharxs
}

struct ToyCharx {
    var hsClientCharx:      CBCharacteristic?      //Used to send ClientId to the Toy
    var hsDeviceCharx:      CBCharacteristic?      //Used to read DeviceID from the toy
    var hsConfirmCharx:     CBCharacteristic?      //Used to confirm the connection. Toy returns the ClientID if confirmed, 0 otherwise
    var toyID:              String = ""
    var lastResponseTime:   CFAbsoluteTime?        //Used to check if a Toy is not responding properly
    var BLEStatus:          BLEConnectionStatus = BLEConnectionStatus.connecting
    var isCharging:         Bool = false
    var isSilent:           Bool = false
}

class TodayViewController: UIViewController, NCWidgetProviding, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Toy BLE status of connection ----------------------------------------------
    var toyStatus: ToyStatus = .disconnected {
        didSet {
            switch toyStatus {  // SEARCHING ----------------------
            case ToyStatus.searching:
                DispatchQueue.main.async{
                    #if DEBUG
                        print("DBG: Go -> ToyStatus.searching")
                    #endif
                    self.scanForPeripheral()
                    self.popParrentAppButton.setTitle("Connecting...", for: UIControlState.normal)
                }
                break
                
            case ToyStatus.connected:  //CONNECTED ---------------------------------
                DispatchQueue.main.async{
                    #if DEBUG
                        print("DBG: Go -> ToyStatus.connected")
                    #endif

                    if self.toyCheckStatusTimer == nil {
                        self.toyCheckStatusTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.checkToyBLEStatus), userInfo: nil, repeats: true)
                    }
                    self.popParrentAppButton.setTitle("Connected", for: UIControlState.normal)
                }
                break
                
            case ToyStatus.disconnected:  // IDLE ---------------------------
                DispatchQueue.main.async{
                    #if DEBUG
                        print("DBG: Go -> ToyStatus.disconnected")
                    #endif
                    
                    self.stopAndInvalidatePeripherals()
                    self.popParrentAppButton.setTitle("Disconnected", for: UIControlState.normal)
                }
                break
                
            case ToyStatus.upgrading:
                DispatchQueue.main.async{
                    #if DEBUG
                        print("DBG: Go -> ToyStatus.upgrading")
                    #endif
                    self.popParrentAppButton.setTitle("KiQ is being upgraded", for: UIControlState.normal)
                    
                    if self.toyCheckStatusTimer == nil {
                        self.toyCheckStatusTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.checkToyBLEStatus), userInfo: nil, repeats: true)
                    }
                }
                break
                
                
            case ToyStatus.resetting:
                DispatchQueue.main.async{
                    #if DEBUG
                        print("DBG: Go -> ToyStatus.resetting")
                    #endif
                    self.popParrentAppButton.setTitle("KiQ is being reset", for: UIControlState.normal)
                }
                break
            }
        }
    }
    
    private var bleStatus: BLEStatus = .off {
        didSet {
            switch bleStatus {
            case .on:
                self.popParrentAppButton.setTitle("Bluetooth is turned On", for: UIControlState.normal)
                self.toyStatus = ToyStatus.searching
                break
            case .off:
                self.toyStatus = ToyStatus.disconnected
                self.popParrentAppButton.setTitle("Bluetooth is turned Off", for: UIControlState.normal)
                break
            }
        }
    }
    
    private var toyCheckStatusTimer: Timer?
    private var myBLECentralManager : CBCentralManager!
    private var discoveredPeripherals = [CBPeripheral]()
    private var discoveredPerifCharxs = [CBPeripheral: ToyCharx]()
    
    private var toyPeripheral: CBPeripheral?
    private var toyCharx : ToyCharx?
    private var toySuplCharx: ToySupplimentaryCharx?
    
    private var toyID: String = ""
    private var clientID = 0
    
    //-----------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    //----------------------------------------------------
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if myBLECentralManager == nil{
            myBLECentralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    //-----------------------------------------------------------------
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-----------------------------------------------------------------
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        prepareForWidgetUpdate()
        completionHandler(NCUpdateResult.newData)
    }
    
    //----------------------------------------------------
    func applicationWillEnterForeground(_ application: UIApplication!) {
        #if DEBUG
            print ("DBG: applicationWillEnterForeground")
        #endif

        if toyStatus == ToyStatus.connected && toyPeripheral?.state == CBPeripheralState.connected {
            //checkToyBattery()
            self.toyCheckStatusTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.checkToyBLEStatus), userInfo: nil, repeats: true)
            return
        }
        
        if bleStatus == .on && toyStatus != ToyStatus.upgrading {
            toyStatus = ToyStatus.searching
            return
        }
        
        if self.toyStatus == ToyStatus.upgrading {
            if toyPeripheral?.state == CBPeripheralState.connected {
                //self.getUpgradeStatus()
            } else {
                toyStatus = ToyStatus.searching
            }
        }
    }
    
    //----------------------------------------------------
    func applicationWillEnterBackground(_ notification: Notification) {
        #if DEBUG
            print ("DBG: applicationWillEnterBackground")
        #endif
        
        self.toyCheckStatusTimer?.invalidate()
        self.toyCheckStatusTimer = nil
    }
    
    @IBOutlet weak var popParrentAppButton: UIButton!
    
    //-----------------------------------------------------------------
    @IBAction func popParrentAppButtonTapped(_ sender: AnyObject) {
        let url: NSURL? = NSURL(string: "KiQToy:")!
        
        if let appurl = url {
            self.extensionContext!.open(appurl as URL,
                                           completionHandler: nil)
        }
    }
    
    //-----------------------------------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        //prepareForWidgetUpdate()
    }
    
    //-----------------------------------------------------------------
    func prepareForWidgetUpdate()
    {
        guard let defaults = UserDefaults.init(suiteName: "group.kiqtoy.com")
            else {return}
        
        clientID = defaults.integer(forKey: "clientID")
        guard let dToyID = defaults.string(forKey: "toyID")
            else { return}
        
        toyID = dToyID
        if clientID != 0 && toyID.isEmpty != true {
            popParrentAppButton.setTitle("Connecting...", for: UIControlState.normal)
        } else {
            popParrentAppButton.setTitle("Connect KiQ to your Phone", for: UIControlState.normal)
        }
    }
    
    //------------------------------------------------------------
    func scanForPeripheral(){
        if bleStatus == .on && toyStatus == ToyStatus.searching{
            let connectedPeripherals = myBLECentralManager.retrieveConnectedPeripherals(withServices: [HS_SERVICE_UUID])
            
            objc_sync_enter(self) //<-----   Enter Critical section
            defer { objc_sync_exit(self) }
            
            
            if(connectedPeripherals.count != 0){
                for peripheral in connectedPeripherals {
                    if !discoveredPeripherals.contains(peripheral) {
                        peripheral.delegate = self
                        self.discoveredPerifCharxs[peripheral] = ToyCharx()
                        self.discoveredPerifCharxs[peripheral]?.lastResponseTime = CFAbsoluteTimeGetCurrent()
                        self.discoveredPerifCharxs[peripheral]?.BLEStatus = BLEConnectionStatus.paired
                        self.discoveredPeripherals.append(peripheral)
                        self.myBLECentralManager.connect(peripheral, options: nil)
                        #if DEBUG
                            print("DBG: scanForPeripheral: " + String(describing: peripheral.name) + " already paired. Connecting...")
                        #endif
                    }
                }
            }
            
            let currentTime = CFAbsoluteTimeGetCurrent()
            
            for peripheral in discoveredPeripherals {
                let timeDiff = currentTime - (discoveredPerifCharxs[peripheral]?.lastResponseTime)!
                if peripheral.state == CBPeripheralState.disconnected || peripheral.state == CBPeripheralState.disconnecting ||
                    (timeDiff > 15 && self.discoveredPerifCharxs[peripheral]?.BLEStatus == BLEConnectionStatus.connecting) ||
                    (timeDiff > 15 && self.discoveredPerifCharxs[peripheral]?.BLEStatus == BLEConnectionStatus.paired) ||
                    (timeDiff > 20 && self.discoveredPerifCharxs[peripheral]?.BLEStatus == BLEConnectionStatus.clientIdSent) {
                    #if DEBUG
                        print("DBG: scanForPeripheral: resetting connection with:" + String (describing: peripheral.name))
                    #endif
                    myBLECentralManager.cancelPeripheralConnection(peripheral)
                    discoveredPerifCharxs.removeValue(forKey: peripheral)
                    discoveredPeripherals.remove(at: discoveredPeripherals.index(of: peripheral)!)
                }
            }
        }//<-------------------------------------------   Leave Critical section
    }
    
    //----------------------------------------------------------
    func checkToyBLEStatus(){
        if toyStatus == ToyStatus.connected || toyStatus == ToyStatus.upgrading{
            if toyPeripheral?.state == CBPeripheralState.connected {
                return
            } else {
                #if DEBUG
                    print("DBG: Connection with Toy lost: .connected -> .disconnected -> .searching ")
                #endif
                toyStatus = ToyStatus.disconnected
                toyStatus = ToyStatus.searching
            }
        }
    }
    
    //----------------------------------------------------
    // Check status of BLE hardware
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            if central.state == CBManagerState.poweredOn {
                bleStatus = .on
            } else {
                bleStatus = .off
            }
        } else {
            if CBCentralManagerState(rawValue: central.state.rawValue) == CBCentralManagerState.poweredOn {
                bleStatus = .on
            } else {
                bleStatus = .off
            }
        }
    }
    
    //---------------- Central Manager Delegates ---------------
    func stopAndInvalidatePeripherals(){
        
        objc_sync_enter(self) //<--- Enter Critical section
        defer { objc_sync_exit(self) }
        
        for peripheral in discoveredPeripherals {
            myBLECentralManager.cancelPeripheralConnection(peripheral)
        }
        discoveredPeripherals.removeAll()
        discoveredPerifCharxs.removeAll()
        
        if toyPeripheral != nil {
            myBLECentralManager.cancelPeripheralConnection(toyPeripheral!)
            toyPeripheral = nil
            toyCharx = nil
            toySuplCharx = nil
        }
        
    } //<---- Leave Critical section
    
    //----------------------------------------------------------
    func theToyIsFound (_ peripheral: CBPeripheral) {
        defer {
            // Clean all previously discovered peripheral, they are not required anymore
            for periph in discoveredPeripherals{
                if periph != peripheral {
                    myBLECentralManager.cancelPeripheralConnection(periph)
                }
            }
            discoveredPerifCharxs.removeAll()
            discoveredPeripherals.removeAll()
        }
        
        self.toyPeripheral = peripheral
        self.toyCharx = self.discoveredPerifCharxs[peripheral]
        self.toySuplCharx = ToySupplimentaryCharx (setup: SetupCharxs(), content: ContentCharxs())
        
        // Post Toy information to the Cloud
        
        print("NORMAL: Known Toy " + String(toyID) + " is connected")
        toyStatus = ToyStatus.connected
        // Request services for the Toy
        peripheral.discoverServices([SETUP_SERVICE_UUID, CONTENT_SERVICE_UUID])
    }
    
    //---------------- Central Manager Delegates ---------------
    //----------------------------------------------------------
    // Peripheral discovered
    /*
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        objc_sync_enter(self) //<--- Enter Critical section
        defer { objc_sync_exit(self) }
        
        #if DEBUG
            print("DBG: New peripheral discovered: ", peripheral.name, ", starting connection")
        #endif
        
        if discoveredPeripherals.contains(peripheral) == false{
            peripheral.delegate = self
            discoveredPeripherals.append(peripheral)
            discoveredPerifCharxs[peripheral] = ToyCharx()
            discoveredPerifCharxs[peripheral]?.lastResponseTime = CFAbsoluteTimeGetCurrent()
            self.myBLECentralManager.connect(peripheral, options: nil)
            #if DEBUG
                print("DBG: Starting connection to", peripheral.name)
            #endif
        }
    } //<---- Leave Critical section
    */
    //----------------------------------------------------------
    // Fail to connect to peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        objc_sync_enter(self) //<--- Enter Critical section
        defer { objc_sync_exit(self) }
        
        #if DEBUG
            print ("ERROR: Did fail to connect to periheral" + String(describing: peripheral.name))
        #endif
        discoveredPerifCharxs.removeValue(forKey: peripheral)
    }//<--- Leave Critical section
    
    //----------------------------------------------------------
    // Peripheral connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([HS_SERVICE_UUID])
        discoveredPerifCharxs[peripheral]?.lastResponseTime = CFAbsoluteTimeGetCurrent()
    }
    
    //----------------------------------------------------------
    // Peripheral disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral) {
        
        objc_sync_enter(self) //<--- Enter Critical section
        defer { objc_sync_exit(self) }
        
        #if DEBUG
            print("DBG: Peripheral disconnected: " + String (describing: peripheral.name))
        #endif
        
        myBLECentralManager.cancelPeripheralConnection(peripheral)
        discoveredPerifCharxs.removeValue(forKey: peripheral)
        discoveredPeripherals.remove(at: discoveredPeripherals.index(of: peripheral)!)
    }//<--- Leave Critical section
    
    //----------------------------------------------------------
    // Discover services for the Perepheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard  error == nil else {
            #if DEBUG
                print("ERROR: didDiscoverServices ->" + String(error.debugDescription))
            #endif
            return
        }
        
        switch toyStatus{
        case ToyStatus.searching:
            for service in peripheral.services! {
                let thisService = service as CBService
                if thisService.uuid == HS_SERVICE_UUID{
                    peripheral.discoverCharacteristics([HS_CLIENTINFO_C, HS_CONFIRMSERV_C, HS_DEVICEINFO_C], for: thisService)
                    discoveredPerifCharxs[peripheral]?.lastResponseTime = CFAbsoluteTimeGetCurrent()
                }
            }
            break
            
        case ToyStatus.connected:
            // ---------- Request supplimentary characteristics ----------------------
            for service in peripheral.services! {
                let thisService = service as CBService
                
                switch service.uuid {
                    
                case SETUP_SERVICE_UUID:
                    peripheral.discoverCharacteristics([SETUP_VOICE_C, SETUP_STATUS_C], for: thisService)
                    break
                    
                case CONTENT_SERVICE_UUID:
                    peripheral.discoverCharacteristics([CONT_PLAYFYLE_C, CONT_FILESPLAYED_C], for: thisService)
                    break
                    
                default:
                    break
                }
            }
            break
            
        case ToyStatus.disconnected:
            #if DEBUG
                print("ERROR: didDiscoverServices: entering, while .disconnected")
            #endif
            break
            
        case ToyStatus.upgrading:
            #if DEBUG
                print("ERROR: didDiscoverServices: entering, while .upgrading")
            #endif
            break
        case ToyStatus.resetting:
            #if DEBUG
                print("ERROR: didDiscoverServices: entering, while .resetting")
            #endif
            break
        }
    }
    
    //----------------------------------------------------------
    // Discover characteristic for the service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard  error == nil else  {
            #if DEBUG
                print("ERROR: didDiscoverCharacteristicsForService ->" + String(error.debugDescription))
            #endif
            return
        }
        
        let charactericsArr = service.characteristics!  as [CBCharacteristic]
        
        objc_sync_enter(self) //<------   Enter Critical Section
        defer { objc_sync_exit(self) }
        
        // ------ Searching for the Toy ---------------------------------------------------
        // ------ Handshake service discovered HS_SERVICE_UUID ----------------------------
        if toyStatus == ToyStatus.searching && service.uuid == HS_SERVICE_UUID{
            for charactericsx in charactericsArr
            {
                if charactericsx.uuid == HS_CLIENTINFO_C{
                    discoveredPerifCharxs[peripheral]?.hsClientCharx = charactericsx
                }
                if charactericsx.uuid == HS_CONFIRMSERV_C{
                    discoveredPerifCharxs[peripheral]?.hsConfirmCharx = charactericsx
                }
                if charactericsx.uuid == HS_DEVICEINFO_C{
                    if  toyPeripheral != peripheral && discoveredPerifCharxs.isEmpty == false {
                        discoveredPerifCharxs[peripheral]?.hsDeviceCharx = charactericsx
                        peripheral.readValue(for: (discoveredPerifCharxs[peripheral]?.hsDeviceCharx)!)
                    } else if toyPeripheral == peripheral {
                        #if DEBUG
                            print("ERROR: didDiscoverCharacteristicsForService toyPeripheral == peripheral")
                        #endif
                        toyStatus = ToyStatus.disconnected
                        toyStatus = ToyStatus.searching
                    } else if discoveredPerifCharxs.isEmpty == true {
                        #if DEBUG
                            print("ERROR: didDiscoverCharacteristicsForService discoveredPerifCharxs.isEmpty == true")
                        #endif
                    }
                }
            }
            discoveredPerifCharxs[peripheral]?.lastResponseTime = CFAbsoluteTimeGetCurrent()
            return
        }
        
        // ------ Toy is connected ---------------------------------------------------------
        if toyStatus == .connected{
            
            switch service.uuid {
                
            // ------ Settings service discovered SETUP_SERVICE_UUID ----------------------------
            case SETUP_SERVICE_UUID:
                for charactericsx in charactericsArr
                {
                    switch charactericsx.uuid {
                        
                    case SETUP_STATUS_C:
                        toySuplCharx?.setup.statusCharx = charactericsx
                        toyPeripheral?.readValue(for: (toySuplCharx?.setup.statusCharx)!)
                        toyPeripheral?.setNotifyValue(true, for: (toySuplCharx?.setup.statusCharx)!)
                        break
                        
                    default:
                        break
                    }
                }
                break
                
            // ------ Content service discovered CONTENT_SERVICE_UUID ----------------------------
            case CONTENT_SERVICE_UUID:
                for charactericsx in charactericsArr
                {
                    switch charactericsx.uuid {
                    case CONT_PLAYFYLE_C:
                        toySuplCharx?.content.playFileCharx = charactericsx
                        break
                    case CONT_FILESPLAYED_C:
                        toySuplCharx?.content.lastPlaiedCharx = charactericsx
                        toyPeripheral?.setNotifyValue(true, for: (toySuplCharx?.content.lastPlaiedCharx)!)
                        break

                    default:
                        break
                    }
                }
                break
                
            default:
                break
            }
        }
    } //<---- Leave Critical Section
    
    
    //----------------------------------------------------------
    // Characteristic was updated
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard  error == nil else {
            #if DEBUG
                print("ERROR: didUpdateValueForCharacteristic: ->" + String(error.debugDescription))
            #endif
            return
        }
        
        objc_sync_enter(self) //<-------   Enter Critical section
        defer {objc_sync_exit(self)}
        
        // *********** Check if we are still searching for the Toy ******************
        if toyStatus == ToyStatus.searching {
            // We are still searching
            if characteristic.uuid == HS_DEVICEINFO_C { // The some Toy has sent to us its ToyID
                guard let data = characteristic.value as NSData?
                    else {return}
                let buffer16 = data.u16s
                let buffer32 = data.u32s
                
                discoveredPerifCharxs[peripheral]?.toyID = String(buffer32[1])
                // Toy was connected to this client and this client has toy's ID
                if  discoveredPerifCharxs[peripheral]?.toyID == toyID {
                    let dataToWrite = encode(UInt32(clientID))
                    peripheral.setNotifyValue(true, for: (discoveredPerifCharxs[peripheral]?.hsConfirmCharx)!)
                    peripheral.writeValue(dataToWrite, for: (discoveredPerifCharxs[peripheral]?.hsClientCharx)!, type: CBCharacteristicWriteType.withResponse)
                    discoveredPerifCharxs[peripheral]?.lastResponseTime = CFAbsoluteTimeGetCurrent()
                    discoveredPerifCharxs[peripheral]?.BLEStatus = BLEConnectionStatus.clientIdSent

                    print ("NORMAL: Sending Client ID: " + String(clientID) + " to Toy " + String(describing: discoveredPerifCharxs[peripheral]?.toyID))
                    
                } else {
                    print("NORMAL: Toy with ID: " + String (describing: discoveredPerifCharxs[peripheral]?.toyID) + " is not the Toy we are looking for")
                }
            } else if characteristic.uuid == HS_CONFIRMSERV_C { // Some Toy has sent us confirmation notification
                
                let readData :UInt32 = decode(characteristic.value!)
                
                if readData == UInt32(clientID) { // The Toy has confirmed connection. Stop scanning, store peripheral as Toy peripheral, request services
                    print("NORMAL: Client ID: " + String(readData) + " was confirmed by Toy " + String(describing: discoveredPerifCharxs[peripheral]?.toyID))
                    theToyIsFound(peripheral)
                } else {
                    print("NORMAL: the Toy has rejected connection with Client ID: " + String (describing: clientID))
                    myBLECentralManager.cancelPeripheralConnection(peripheral)
                    discoveredPerifCharxs.removeValue(forKey: peripheral)
                    discoveredPeripherals.remove(at: discoveredPeripherals.index(of: peripheral)!)
                }
            }
            
            // *********** Check if we are connected to the Toy ******************
        } else if toyStatus == ToyStatus.connected {
            
            switch characteristic.uuid { // ---- Toy is connected. Some Characteristic was updated
                
                
            case SETUP_STATUS_C:
                guard let data = characteristic.value as NSData?
                    else {return}
                let array = data.u8s
                
                if array.count >= 3 {
                    var toyBatteryLevel: UInt8 = array[0]
                    let toyBatteryStatus: UInt8 = array[1]
                    var toySilentStatus: UInt8 = 0
                    if array.count > 3 {
                        toySilentStatus = array[3]
                    } else {
                        toySilentStatus = array[2]
                    }
                    if toyBatteryLevel > 100 {
                        toyBatteryLevel = 100
                    }
                    if toyBatteryStatus >= 1 {
                        toyCharx?.isCharging = true
                    } else {
                        toyCharx?.isCharging = false
                    }
                    if toySilentStatus == 1 {
                        toyCharx?.isSilent = true
                    } else {
                        toyCharx?.isSilent = false
                    }
                    print(toyBatteryLevel)
                }
                break
                
            case CONT_FILESPLAYED_C:
                guard let data = characteristic.value as NSData?
                    else {return}
                let buffer16 = data.u16s
                var buffer32 = data.u32s
                
                let fileOffset = buffer16[0]
                let numOfFiles = buffer16[1]
                
                if numOfFiles == 0 { // numOfFiles is 0 if this is notification about just played file
                    #if DEBUG
                        print ("DBG: Last file played received")
                    #endif
                }
                break
   
            default:
                break
            }
        } else if toyStatus == ToyStatus.upgrading {
            switch characteristic.uuid {
                
            default:
                break
            }
        }
    } //<------ Leave Critical section
    
    
    // NSData to struct and back
    //------------------------------------------------------------
    private func encode<T> (_ value_: T) -> Data {
        var value = value_
        return withUnsafePointer(to: &value) { p in
            Data(bytes: p, count: MemoryLayout<T>.size)
        }
    }
    
    
    //------------------------------------------------------------
    private func encodeWithMaxLenght<T> (_ value_: T, length: Int) -> Data {
        var value = value_
        if MemoryLayout<T>.size < length {
            return withUnsafePointer(to: &value) { p in
                Data(bytes: p, count: MemoryLayout<T>.size)
            }
        } else {
            return withUnsafePointer(to: &value) { p in
                Data(bytes: p, count: length)
            }
        }
    }
    
    
    //------------------------------------------------------------
    private func decode<T>(_ data: Data) -> T {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: MemoryLayout<T.Type>.size)
        (data as NSData).getBytes(pointer, length: MemoryLayout<T>.size)
        return pointer.move()
    }
}
