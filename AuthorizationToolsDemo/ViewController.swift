//
//  ViewController.swift
//  AuthorizationToolsDemo
//
//  Created by 郑小燕 on 2017/11/16.
//  Copyright © 2017年 郑小燕. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let titleArray = ["访问定位服务权限", "访问通讯录权限", "访问日历权限", "访问提醒事项权限", "访问照片权限", "访问蓝牙共享权限", "访问麦克风权限", "访问语音识别权限", "访问相机权限", "访问健康权限", "访问HomeKit权限", "访问媒体与Apple Music权限", "访问运动与健身权限"]
    let detailTileArray = ["Location Services", "Contacts", "Calendars", "Reminders", "Photos", "Bluetooth  Sharing", "Microphone", "Speech Recognition", "Camera", "Health", "HomeKit", "Media & AppleMusic", "Motion & Fitness"]
    var tools: AuthorizationManager!
    
    
    
    @IBOutlet weak var tableViewList: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableViewList.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! UITableViewCell
        cell.textLabel?.text = titleArray[indexPath.row]
        cell.detailTextLabel?.text = detailTileArray[indexPath.row]
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 43
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tools = AuthorizationManager()
        print("当前系统版本: \(UIDevice.current.systemVersion)")
        self.tools = AuthorizationManager()
        let string = detailTileArray[indexPath.row]
        
        if string == "Location Services" {
            self.tools.check(for: .LocationServices, callBack: { (type: AMPrivacyType, status: AMPrivacyStatus) in
                if type == .LocationServices {
                    switch status {
                    case .Authorized:
                        print("已授权")
                    case .NotDetermined:
                        print("NotDetermined")
                    case .Denied:
                        print("Denied")
                    case .Restricted:
                        print("Restricted")
                    case .CLAuthorizedAlways:
                        print("AuthorizedAlways")
                    case .CLauthorizedWhenInUse:
                        print("authorizedWhenInUse")
                    case .NotSupport:
                        print("未打开定位服务")
                    default:
                        print("其他")
                    }
        
                }
            })
        } else if string == "Contacts" {
            self.tools.check(for: .Contacts, callBack: { (type: AMPrivacyType, status: AMPrivacyStatus) in
                if type == .Contacts {
                    switch status {
                    case .Authorized:
                        print("Authorized")
                    case .NotDetermined:
                        print("NotDetermined")
                    case .Restricted:
                        print("Restricted")
                    case .Denied:
                        print("Denied")
                    default:
                        print("其他")
                    }
                    
                }
            })
        } else if string == "Calendars" {
            self.tools.check(for: .Calendars, callBack: { (type: AMPrivacyType, status: AMPrivacyStatus) in
                if type == .Calendars {
                    switch status {
                    case .Authorized:
                        print("Authorized")
                    case .Denied:
                        print("denied")
                    case .NotDetermined:
                        print("NotDetermined")
                    case .Restricted:
                        print("Restricted")
                        
                    case .NotSupport:
                        print("NotSupport")
                    default:
                        print("default")
                    }
                }
            })
        } else if string == "Photos" {
            self.tools.check(for: .Photos, callBack: { (type: AMPrivacyType, status: AMPrivacyStatus) in
                switch status {
                case .Authorized:
                    print("Authorized")
                case .NotSupport:
                    print("NotSupport")
                case .Restricted:
                    print("restricted")
                case .Denied:
                    print("denied")
                default:
                    break
                    
                }
            })
        } else if string == "Camera" {
            self.tools.check(for: .Camera, callBack: { (type: AMPrivacyType, status: AMPrivacyStatus) in
                switch status {
                case .Authorized:
                    print("Authorized")
                case .NotSupport:
                    print("NotSupport")
                case .Restricted:
                    print("restricted")
                case .Denied:
                    print("denied")
                default:
                    break
                    
                }
            })
        }
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

