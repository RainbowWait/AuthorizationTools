//
//  AuthorizationManager.swift
//  
// 应用权限检查
//  Created by leecong on 2017/11/9.
//

import UIKit
import AssetsLibrary
import Photos
import AddressBook
import Contacts
import AVFoundation
import CoreBluetooth
import CoreLocation
import EventKit
import Speech
import HomeKit
import HealthKit
import StoreKit
import CoreMotion

/// 权限请求类型
enum AMPrivacyType {
    case None                   //
    case LocationServices       // 定位
    case Contacts               // 通讯录
    case Calendars              // 日历
    case Reminders              // 提醒事项
    case Photos                 // 照片
    case BluetoothSharing       // 蓝牙共享
    case MicroPhone             // 麦克风
    case SpeechRecognition      // 语音识别 >= 10.0
    case Camera                 // 相机
    case Health                 // 健康 >= 8.0
    case HomeKit                // 家庭 >= 8.0
    case MediaAndAppleMusic     // 媒体与Apple music > 9.3
    case MotionAndFitness       // 运动和健身
}

/// 权限返回状态
enum AMPrivacyStatus {
    
    case NotSupport             // 硬件不支持
    case Denied                 // 拒绝
    case NotDetermined          // 还未进行授权处理
    case Restricted             // 应用没有相关权限，当前用户无法改变权限 比如:家长控制
    case Authorized             // 已授权
    //定位
    case CLAuthorizedAlways     //
    case CLauthorizedWhenInUse  //
    
    //蓝牙
    case BTUnknown                 //状态未知
    case BTResetting              //重置
    case BTUnauthorized           //未授权
    case BTPoweredOff             //关闭
    case BTPoweredOn              //可使用
    
}




@available(iOS 10.0, *)
class AuthorizationManager: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate, HMHomeManagerDelegate{
    typealias AMPrivacyCallBack = (_ aType : AMPrivacyType , _ status : AMPrivacyStatus) -> Void
    typealias HomeKitCallBack = (_ aType : AMPrivacyType , _ status : Bool) -> Void
    typealias AccessForHomeResult = (_ isHaveHomeAccess: Bool) -> Void
    @available(iOS 10.0, *)
    typealias CBManagerStateCallBack = (_ state: CBManagerState) -> Void
    private var cbCallBack: CBManagerStateCallBack?
    private var healthStore: HKHealthStore?
    private var locationManager : CLLocationManager?
    private var cMgr: CBCentralManager?
    private var homeManager: HMHomeManager?
    private var homeResult: AccessForHomeResult?
    private var cmManager: CMMotionActivityManager? //运动
    private var motionActivityQueue: OperationQueue?
    
    public func check(`for` aType : AMPrivacyType ,and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        switch aType {
        case .LocationServices:
            checkLoaction(callBack: callBack);break
        case .Camera: checkCamera(callBack: callBack);break
        case .Photos: checkPhotos(callBack: callBack);break
        case .MicroPhone : checkMicroPhone(callBack: callBack);break
        case .Contacts: checkContacts(callBack: callBack);break
        case .Calendars: checkCalendar(callBack: callBack);break
        case .Reminders: checkReminder(callBack: callBack)
        case .BluetoothSharing: checkBluetoothSharing(callBack: callBack)
        case .SpeechRecognition: checkBluetoothSharing(callBack: callBack)
        case .Health : checkHealth(callBack: callBack)
        case .MediaAndAppleMusic: checkAppleMusic(callBack: callBack)
        case .MotionAndFitness: checkMotionAndFitness(callBack: callBack)
        default:
            break
        }
    }
    //MARK: 检查定位权限
    
    /// 检查定位权限
    ///
    /// - Parameters:
    ///   - RequestAccess: 假如未请求过授权是否进行授权请求
    ///   - callBack: 回调函数
    private func checkLoaction(and RequestAccess : Bool = true , callBack : AMPrivacyCallBack){
        guard CLLocationManager.locationServicesEnabled() else {
            callBack(.LocationServices,.NotSupport)
            return
        }
        let status = CLLocationManager.authorizationStatus()
        
        var statusback : AMPrivacyStatus = .Authorized
        switch status {
        case .notDetermined:
            if RequestAccess{
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
                // 请求一直使用定位的权限
                self.locationManager?.requestAlwaysAuthorization()
                checkLoaction(and: RequestAccess,callBack: callBack)
            }else{
                statusback = .NotDetermined
            };break
        case .denied:
            statusback = .Denied;break
        case .authorizedAlways:
            statusback = .CLAuthorizedAlways;break
        case .authorizedWhenInUse:
            statusback = .CLauthorizedWhenInUse;break
        case .restricted:
            statusback = .Restricted;break
        }
        callBack(.LocationServices, statusback)
    }
    //MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
       
    }
    
    
    //MARK: - 访问通讯录
    private func checkContacts(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        if #available(iOS 9.0, *) {
            let status = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
            switch status{
        case .authorized:callBack(.Contacts, .Authorized);break
            case .denied:callBack(.Contacts, .Denied);break
            case .notDetermined:
                if RequestAccess{
                    let contact = CNContactStore()
                    contact.requestAccess(for: .contacts, completionHandler: { (granted, isError) in
                        DispatchQueue.main.async {
                            if isError != nil{
                                callBack(.Contacts, .NotSupport)
                            }else{
                                callBack(.Contacts, granted ? AMPrivacyStatus.Authorized : AMPrivacyStatus.Denied)
                            }
                        }
                    })
                }else{
                    callBack(.Contacts , .NotDetermined)
                }
                break
            case .restricted:callBack(.Contacts, .Restricted);break
            }
        }else{/// 9.0版本以下下
            let status = ABAddressBookGetAuthorizationStatus()
            switch status {
            case .notDetermined:
                if RequestAccess {
                    let addressBookRef = ABAddressBookCreateWithOptions(nil, nil)
        ABAddressBookRequestAccessWithCompletion(addressBookRef as ABAddressBook, { (granted, error) in
                callBack(.Contacts, granted ? .Authorized : .Denied)
                    })
                } else {
                    callBack(.Contacts, .NotDetermined)
                }
            case .denied:
                callBack(.Contacts, .Denied)
            case .authorized:
                callBack(.Contacts, .Authorized)
            case .restricted:
                callBack(.Contacts, .Restricted)
                
            }
        }
    }
    
    //MARK: - 日历
    private func checkCalendar(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        switch status {
        case .authorized:
            callBack(.Calendars, .Authorized)
        case .denied:
            callBack(.Calendars, .Denied)
        case .notDetermined:
            if RequestAccess {
                let store = EKEventStore()
                store.requestAccess(to: EKEntityType.event, completion: { (granted, error) in
                    if error != nil {
                        callBack(.Calendars, .Denied)
                    }
                    if granted {
                        callBack(.Calendars, .Authorized)
                    } else {
                        callBack(.Calendars, .Denied)
                    }
                })
                
            } else {
                callBack(.Calendars, .NotDetermined)
            }
        case .restricted:
       callBack(.Calendars, .Restricted)
        }
        
        
    }
    //MARK: - Reminders
    private func checkReminder(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        let status = EKEventStore.authorizationStatus(for: EKEntityType.reminder)
        switch status {
        case .authorized:
            callBack(.Reminders, .Authorized)
        case .denied:
            callBack(.Reminders, .Denied)
        case.notDetermined:
            if RequestAccess {
                let store = EKEventStore()
                store.requestAccess(to: EKEntityType.reminder, completion: { (granted, error) in
                    if error != nil {
                        callBack(.Reminders, .Denied)
                    }
                    if granted {
                        callBack(.Reminders, .Authorized)
                    } else {
                     callBack(.Reminders, .Denied)
                    }
                })
                
            } else {
                callBack(.Reminders, .NotDetermined)
            }
        case .restricted:
            callBack(.Reminders, .Restricted)
        }
        
    }
    
    //MARK: 相册权限检查
    
    /// check photo album rights
    ///
    /// - Parameters:
    ///   - RequestAccess: 如果为未检查状态是否弹框请求
    ///   - callBack: 回调函数
    private func checkPhotos(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            callBack(.Photos , .NotSupport)
            return
        }
        if #available(iOS 8.0, *) {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status{
            case .authorized:callBack(.Photos , .Authorized);break
            case .denied:callBack(.Photos , .Denied);break
            case .notDetermined:
                if RequestAccess{
                    PHPhotoLibrary.requestAuthorization({ (status) in
                        DispatchQueue.main.async {
                            switch status{
                            case .authorized:callBack(.Photos , .Authorized);break
                            case .denied:callBack(.Photos , .Denied);break
                            default: break
                            }
                            
                        }
                    })
                }else{
                    callBack(.Photos , .NotDetermined)
                }
                break
            case .restricted:callBack(.Photos , .Restricted);break
            }
        }else{
            /// 好像iOS8一下不用管
        }
    }
    //MARK: - 蓝牙
    private func checkBluetoothSharing(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        self.cMgr = CBCentralManager(delegate: self, queue: nil)
//        if #available(iOS 10.0, *) {
            self.cbCallBack = { (state: CBManagerState) in
                switch state {
                case .resetting:
                    callBack(.BluetoothSharing,.BTResetting)
                case .unsupported:
                    callBack(.BluetoothSharing, .NotSupport)
                case .unknown:
                    callBack(.BluetoothSharing, .BTUnknown)
                case .unauthorized:
                    callBack(.BluetoothSharing, .BTUnauthorized)
                case .poweredOff:
                    callBack(.BluetoothSharing, .BTPoweredOff)
                case .poweredOn:
                    callBack(.BluetoothSharing, .BTPoweredOn)
                }
               
                
            }
//        } else {
//            // Fallback on earlier versions
//        }
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if self.cbCallBack != nil {
            self.cbCallBack!(central.state)
        }
    }
    
    //MARK: 检查麦克风权限
    
    /// 检查麦克风权限
    ///
    /// - Parameters:
    ///   - RequestAccess: 同上
    ///   - callBack: 回调函数
    private func checkMicroPhone(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        switch status{
        case .authorized:callBack(.Photos , .Authorized);break
        case .denied:callBack(.Photos , .Denied);break
        case .notDetermined:
            if RequestAccess{
                AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                    DispatchQueue.main.async {
                        if granted{
                            callBack(.MicroPhone , .Authorized)
                        }else{
                            callBack(.MicroPhone , .Denied)
                        }
                    }
                })
            }else{
                callBack(.Photos , .NotDetermined)
            }
            break
        case .restricted:callBack(.Photos , .Restricted);break
        }
    }
    //MARK: 语音识别
    private func checkSpeechRecognition(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        if #available(iOS 10.0, *) {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            callBack(.SpeechRecognition, .Authorized)
        case .denied:
            callBack(.SpeechRecognition, .Denied)
        case .notDetermined:
            if RequestAccess {
                SFSpeechRecognizer.requestAuthorization({ (status) in
                    switch status {
                    case .authorized:
                        callBack(.SpeechRecognition, .Authorized)
                    case .denied:
                        callBack(.SpeechRecognition, .Denied)
                    case .notDetermined:
                        callBack(.SpeechRecognition, .NotDetermined)
                    case .restricted:
                        callBack(.SpeechRecognition, .Restricted)
                        
                    }
                })
            } else {
              callBack(.SpeechRecognition, .NotDetermined)
            }
        case .restricted:
            callBack(.SpeechRecognition, .Restricted)
        }
        }else{
            callBack(.SpeechRecognition, .NotSupport)
        }
        
    }
    //MARK: - 相机
    private func checkCamera(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            callBack(.Camera , .NotSupport)
            return
        }
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch status{
        case .authorized:callBack(.Photos , .Authorized);break
        case .denied:callBack(.Photos , .Denied);break
        case .notDetermined:
            if RequestAccess{
                AVCaptureDevice.requestAccess(for: AVMediaType.video) { (granted) in
                    DispatchQueue.main.async {
                        if granted{
                            callBack(.Photos , .Authorized)
                        }else{
                            callBack(.Photos , .Denied)
                        }
                    }
                }
            }else{
                callBack(.Photos , .NotDetermined)
            }
            break
        case .restricted:callBack(.Photos , .Restricted);break
        }

    }
    //MARK: - Health
    private func checkHealth(and RequestAccess : Bool = true , callBack : AMPrivacyCallBack){
        if #available(iOS 8.0, *) {
            if HKHealthStore.isHealthDataAvailable() {
                if self.healthStore == nil {
                    self.healthStore = HKHealthStore()
                }
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
                let status: HKAuthorizationStatus = (self.healthStore?.authorizationStatus(for: heartRateType!))!
                switch status {
                case .notDetermined:
//                    if RequestAccess {
//
//                    } else {
                        callBack(.Health, .NotDetermined)
//                    }
                case .sharingDenied:
               callBack(.Health, .Denied) case .sharingAuthorized:
                    callBack(.Health, .Authorized)
                }
                
                
            } else {
                callBack(.Health, .NotSupport)
            }
        } else {
            callBack(.Health, .NotSupport)
        }
    }
    //MARK: - HomeKit
    private func checkHomeKit(and RequestAccess : Bool = true , callBack : @escaping HomeKitCallBack){
        if #available(iOS 8.0, *) {
            if self.homeManager == nil {
                self.homeManager = HMHomeManager()
                self.homeManager?.delegate = self
                self.homeResult = {(isHaveAccess: Bool) in
                    callBack(.HomeKit, isHaveAccess)
                }
            }
        } else {
            print("The home is available on ios8 or later")
        }
        
    }
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if manager.homes.count > 0 {
            print("A home exists, so we have access.")
            if self.homeResult != nil  {
                self.homeResult!(true)
            }
        } else {
            manager.addHome(withName: "Test Home", completionHandler: { (home: HMHome?, error: Error?) in
                if error == nil {
                    print("We have access for home.")
                    if self.homeResult != nil {
                        self.homeResult!(true)
                    }
                } else {
//                    if error.rawValue == HMError.homeAccessNotAuthorized.rawValue {
//                        print("用户拒绝")
//                    } else {
//                        print("HOME_ERROR:\(error?.code), \(error?.localizedDescription)")
//                    }
                    if self.homeResult != nil{
                        self.homeResult!(false)
                    }
                }
                if home != nil {
                    self.homeManager?.removeHome(home!, completionHandler: { (error: Error?) in
                        
                        })
                }
                })
        }
    }
    //MARK: - MediaAndAppleMusic
    private func checkAppleMusic(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        if #available(iOS 9.3, *) {
            let status = SKCloudServiceController.authorizationStatus()
            switch status {
            case .authorized:
                callBack(.MediaAndAppleMusic, .Authorized)
            case .denied:
                callBack(.MediaAndAppleMusic, .Denied)
            case .notDetermined:
                if RequestAccess {
            SKCloudServiceController.requestAuthorization({ (status: SKCloudServiceAuthorizationStatus) in
                switch status {
                case .authorized:
                    callBack(.MediaAndAppleMusic, .Authorized)
                case .denied:
                    callBack(.MediaAndAppleMusic, .Denied)
                case .notDetermined:
                    callBack(.MediaAndAppleMusic, .NotDetermined)
                case .restricted:
                    callBack(.MediaAndAppleMusic, .Restricted)
                }
                    })
                } else {
                    callBack(.MediaAndAppleMusic, .NotDetermined)
                }
            case .restricted:
                callBack(.MediaAndAppleMusic, .Restricted)
            }
        } else {
            callBack(.MediaAndAppleMusic, .NotSupport)
        }
        
    }
    
    //MARK: - MotionAndFitness
    private func checkMotionAndFitness(and RequestAccess : Bool = true , callBack : @escaping AMPrivacyCallBack){
        self.cmManager = CMMotionActivityManager()
        self.motionActivityQueue = OperationQueue()
        self.cmManager?.startActivityUpdates(to: self.motionActivityQueue!, withHandler: { (activity) in
            self.cmManager?.stopActivityUpdates()
            print("We have access for MotionAndFitness.")
            callBack(.MotionAndFitness, .Authorized)
        })
        print("We don't have permission to MotionAndFitness.")
        callBack(.MotionAndFitness, .Denied)
    }
    
    
    private func getStatus(){}
}
