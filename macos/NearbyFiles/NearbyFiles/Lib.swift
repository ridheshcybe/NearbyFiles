//
//  Lib.swift
//  NearbyFiles
//
//  Created by ridhesh on 24/07/25.
//

import Foundation
import UserNotifications

class Notify {
    static let shared = Notify()
    private let center = UNUserNotificationCenter.current()
    private var didRequestAuthorization = false
    
    private init() {
        requestAuthorizationIfNeeded()
    }
    
    private func requestAuthorizationIfNeeded() {
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied: \(String(describing: error))")
            }
        }
    }
    
    func sendNotification(title: String, body: String, sound: UNNotificationSound = .default) {
        // Ensure authorization is requested (safe if called multiple times)
        requestAuthorizationIfNeeded()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        center.add(request) { error in
            if let error = error {
                print("Failed to add notification: \(error)")
            }
        }
    }
}
