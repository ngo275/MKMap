//
//  NotificationManager.swift
//  MKMap
//
//  Created by ShuichiNagao on 2016/12/12.
//  Copyright © 2016 ShuichiNagao. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationManager {
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
        
        }
    }
    
    static func notify() {
        let content = UNMutableNotificationContent()
        content.title = "Hi, there!"
        content.body = "I am implementing notification!!"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (3), repeats: false)
        
        let requestId = "abc"
        let request = UNNotificationRequest(
            identifier: requestId,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { (error) in
            
        }
    }
    
}
